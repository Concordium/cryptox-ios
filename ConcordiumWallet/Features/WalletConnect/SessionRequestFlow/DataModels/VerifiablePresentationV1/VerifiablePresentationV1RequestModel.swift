//
//  VerifiablePresentationV1RequestModel.swift
//  CryptoX
//
//  Created on 2026.
//  Copyright © 2026 Concordium. All rights reserved.
//

import Foundation
import ReownWalletKit
import Combine
import Concordium
import ConcordiumWalletCrypto
import SwiftCBOR

final class VerifiablePresentationV1RequestModel: ObservableObject, SessionRequestDataProvidable {
    @Published var title: String = "Anonymous Verification request"
    @Published var subtitle: String?
    @Published var error: VerifiableStatementError?
    @Published var isLoadingAnchor: Bool = true
    @Published var anchorLoadError: String?
    
    let requestV1: RequestV1
    let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    let concordiumClient: ConcordiumClient
    private let identitiesService: SeedIdentitiesService
    private let storageManager: StorageManagerProtocol
    
    // Store original JSON to extract source and all issuers for anchor verification
    let originalRequestJSON: [String: Any]
    
    // Anchor data loaded in background
    var anchorBlockHash: String?
    var globalContext: GlobalContext?
    var transactionRef: String?
    
    init(
        requestV1: RequestV1,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        storageManager: StorageManagerProtocol,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService
    ) {
        self.requestV1 = requestV1
        self.account = account
        self.sessionRequest = sessionRequest
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        self.storageManager = storageManager
        self.concordiumClient = concordiumClient
        self.identitiesService = identitiesService
        
        var originalJSON: [String: Any] = [:]
        if let paramsValue = sessionRequest.params.value as? String,
           let jsonData = paramsValue.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            originalJSON = json
            self.transactionRef = json["transactionRef"] as? String
        } else if let paramsDict = sessionRequest.params.value as? [String: Any] {
            originalJSON = paramsDict
            self.transactionRef = paramsDict["transactionRef"] as? String
        }
        self.originalRequestJSON = originalJSON
        
        self.subtitle = generateSubtitle()
        
        Task {
            await loadAnchorData()
        }
    }
    
    private func generateSubtitle() -> String {
        let statements = extractStatements()
        if let firstStatement = statements.first {
            switch firstStatement {
            case .attributeValue:
                return "Attribute Verification"
            case .attributeInRange:
                return "Age Verification"
            case .attributeInSet:
                return "Country Verification"
            case .attributeNotInSet:
                return "Country Verification"
            }
        }
        return "Verification Request"
    }
    
    func extractStatements() -> [AtomicStatementV1] {
        return requestV1.subjectClaims.flatMap { claim in
            switch claim {
            case .account(let accountClaims):
                return accountClaims.statements
            case .identity(let identityClaims):
                return identityClaims.statements
            }
        }
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        while isLoadingAnchor {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        if anchorLoadError != nil {
            return false
        }
        
        return true
    }
    
    @MainActor
    func approveRequest() async throws {
        guard error == nil else {
            throw GeneralAppError.somethingWentWrong
        }
        
        guard let anchorBlockHash = anchorBlockHash,
              let globalContext = globalContext else {
            throw SessionRequstError.generic("Failed to load anchor data")
        }
        
        do {
            let pass = try await passwordDelegate.requestUserPassword(keychain: KeychainWrapper())
            let phrase = try await identitiesService.mobileWallet.getRecoveryPhrase(pwHash: pass)
            let seed = phrase.joined(separator: " ")
            
            let walletSeed = try Helper.decodeSeed(seed, ConcordiumClient.network)
            
            let providedContext = try buildProvidedContext(anchorBlockHash: anchorBlockHash)
            
            let mergedRequest = mergeProvidedContextIntoRequest(providedContext)
            
            let effectiveRequest = try resolveSubjectClaimsForSource(in: mergedRequest)
            
            let extractedData = try extractRealmData(subjectClaims: effectiveRequest.subjectClaims)
            
            let proofInputs = try await createProofInputs(
                subjectClaims: effectiveRequest.subjectClaims,
                walletSeed: walletSeed,
                password: pass,
                extractedData: extractedData
            )
            
            let zkpPresentation = try ZKPFactory.makeVerifiablePresentationV1(
                request: effectiveRequest,
                global: globalContext,
                inputs: proofInputs
            )
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(zkpPresentation)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            let outerObject: [String: Any] = [
                "verifiablePresentationJson": jsonObject
            ]
            
            try await Sign.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .response(AnyCodable(any: outerObject))
            )
        } catch {
            if let nsError = error as NSError? {
                LegacyLogger.error("VerifiablePresentationV1: approveRequest failed \(nsError.domain) \(nsError.code)")
            }
            throw error
        }
    }
    
    // MARK: - Realm Data Extraction (must be done on main thread)
    
    /// Extracted data from Realm objects to avoid thread access issues
    private struct ExtractedRealmData {
        struct IdentityData {
            let ipInfo: IPInfo
            let arsInfosDict: [String: ArsInfo]
            let metadata: Metadata
            let seedIdentityObjectJSON: String
            let index: Int
            let ipIdentity: Int
        }
        
        struct AccountData {
            let ipIdentity: Int
            let identityObjectJSON: String
            let encryptedCommitmentsRandomnessKey: String?
        }
        
        let identityData: IdentityData?
        let accountData: AccountData?
    }
    
    /// Extract all Realm data on main thread before async work
    @MainActor
    private func extractRealmData(subjectClaims: [SubjectClaims]) throws -> ExtractedRealmData {
        var identityData: ExtractedRealmData.IdentityData?
        var accountData: ExtractedRealmData.AccountData?
        
        // Extract identity data if needed
        for subjectClaim in subjectClaims {
            if case .identity = subjectClaim {
                guard let identityEntity = account.identityEntity,
                      let identityProvider = identityEntity.identityProvider,
                      let ipInfo = identityProvider.ipInfo,
                      let arsInfosDict = identityProvider.arsInfos,
                      let seedIdentityObjectJSON = try identityEntity.seedIdentityObject?.json() else {
                    throw SessionRequstError.generic("Account has no identity or missing identity data")
                }
                
                identityData = ExtractedRealmData.IdentityData(
                    ipInfo: ipInfo,
                    arsInfosDict: arsInfosDict,
                    metadata: Metadata(
                        support: identityProvider.support,
                        issuanceStart: identityProvider.issuanceStartURL,
                        recoveryStart: identityProvider.recoveryStartURL,
                        icon: identityProvider.icon,
                        display: nil
                    ),
                    seedIdentityObjectJSON: seedIdentityObjectJSON,
                    index: identityEntity.index,
                    ipIdentity: ipInfo.ipIdentity
                )
                break
            }
        }
        
        // Extract account data if needed
        for subjectClaim in subjectClaims {
            if case .account = subjectClaim {
                guard let identityEntity = account.identityEntity,
                      let ipIdentity = identityEntity.identityProvider?.ipInfo?.ipIdentity,
                      let identityObjectJSON = try identityEntity.seedIdentityObject?.json() else {
                    throw SessionRequstError.generic("Account has no identity or missing identity data")
                }
                
                accountData = ExtractedRealmData.AccountData(
                    ipIdentity: ipIdentity,
                    identityObjectJSON: identityObjectJSON,
                    encryptedCommitmentsRandomnessKey: account.encryptedCommitmentsRandomness
                )
                break
            }
        }
        
        return ExtractedRealmData(identityData: identityData, accountData: accountData)
    }
    
    private func createProofInputs(
        subjectClaims: [SubjectClaims],
        walletSeed: WalletSeed,
        password: String,
        extractedData: ExtractedRealmData
    ) async throws -> [OwnedCredentialProofPrivateInputs] {
        var proofInputs: [OwnedCredentialProofPrivateInputs] = []
        
        // For each subject claim, create the appropriate proof input
        for subjectClaim in subjectClaims {
            switch subjectClaim {
            case .identity(let identityClaims):
                guard let identityData = extractedData.identityData else {
                    throw SessionRequstError.generic("Missing identity data")
                }
                let proofInput = try await createIdentityProofInput(
                    identityClaims: identityClaims,
                    identityData: identityData,
                    walletSeed: walletSeed
                )
                proofInputs.append(.identity(identity: proofInput))
                
            case .account(let accountClaims):
                guard let accountData = extractedData.accountData else {
                    throw SessionRequstError.generic("Missing account data")
                }
                let proofInput = try await createAccountProofInput(
                    accountClaims: accountClaims,
                    accountData: accountData,
                    password: password
                )
                proofInputs.append(.account(account: proofInput))
            }
        }
        return proofInputs
    }

    /// If a request asks for identity claims but only allows account credentials
    /// as a source, convert those claims into account-based claims using the
    /// wallet's account credential registration id.
    private func resolveSubjectClaimsForSource(in request: RequestV1) throws -> RequestV1 {
        guard let subjectClaimsArray = originalRequestJSON["subjectClaims"] as? [[String: Any]] else {
            return request
        }
        
        let resolvedClaims: [SubjectClaims] = try request.subjectClaims.enumerated().map { index, claim in
            guard index < subjectClaimsArray.count else { return claim }
            let claimDict = subjectClaimsArray[index]
            let sourceStrings = (claimDict["source"] as? [String]) ?? []
            let sources = sourceStrings.compactMap { value -> IdentityCredentialType? in
                switch value {
                case "identityCredential": return .identityCredential
                case "accountCredential": return .accountCredential
                default: return nil
                }
            }
            
            guard case .identity(let identityClaims) = claim else {
                return claim
            }
            
            let allowsIdentity = sources.contains(.identityCredential)
            let allowsAccount = sources.contains(.accountCredential)
            let preferAccountWhenBothSources = true
            if allowsAccount && (!allowsIdentity || preferAccountWhenBothSources) {
                let credId = try accountCredentialId()
                let accountClaims = AccountBasedSubjectClaims(
                    network: identityClaims.network,
                    issuer: identityClaims.issuer,
                    credId: credId,
                    statements: identityClaims.statements
                )
                return .account(account: accountClaims)
            }
            
            return claim
        }
        
        return RequestV1(context: request.context, subjectClaims: resolvedClaims)
    }
    
    private func accountCredentialId() throws -> Bytes {
        guard let credential = account.credential,
              let credIdString = credential.value.credential.contents.dictionary["credId"] as? String,
              let credIdData = Data(hexString: credIdString) else {
            throw SessionRequstError.generic("Missing account credential registration id")
        }
        return Bytes(credIdData)
    }
    
    private func createIdentityProofInput(
        identityClaims: IdentityBasedSubjectClaims,
        identityData: ExtractedRealmData.IdentityData,
        walletSeed: WalletSeed
    ) async throws -> OwnedIdentityCredentialProofPrivateInputs {
        let ipInfoResponseElement = IPInfoResponseElement(
            ipInfo: identityData.ipInfo,
            arsInfos: identityData.arsInfosDict,
            metadata: identityData.metadata
        )
        
        let ipInfoSDK = try convertToIdentityProviderInfo(ipInfo: ipInfoResponseElement)
        let arsInfos = try convertToArInfos(ipInfo: identityData.ipInfo, arsInfosDict: identityData.arsInfosDict)
        
        guard let identityObjectData = identityData.seedIdentityObjectJSON.data(using: .utf8) else {
            throw SessionRequstError.generic("Failed to convert identity object JSON to data")
        }
        let identityObjectCrypto = try JSONDecoder().decode(Concordium.IdentityObject.self, from: identityObjectData)
        
        let identityIndexes = IdentitySeedIndexes(
            providerID: IdentityProviderID(identityData.ipIdentity),
            index: IdentityIndex(identityData.index)
        )
        
        let idCredSec = try walletSeed.credSec(identityIndexes: identityIndexes)
        let prfKey = try walletSeed.prfKey(identityIndexes: identityIndexes)
        let signatureBlindingRandomness = try walletSeed.signatureBlindingRandomness(identityIndexes: identityIndexes)
        
        let idObjectUseData = try createIdObjectUseData(
            idCredSec: idCredSec,
            prfKey: prfKey,
            signatureBlindingRandomness: signatureBlindingRandomness,
            identityObject: identityObjectCrypto
        )
        
        return OwnedIdentityCredentialProofPrivateInputs(
            ipInfo: ipInfoSDK,
            arsInfos: arsInfos,
            idObject: identityObjectCrypto,
            idObjectUseData: idObjectUseData
        )
    }
    
    private func createAccountProofInput(
        accountClaims: AccountBasedSubjectClaims,
        accountData: ExtractedRealmData.AccountData,
        password: String
    ) async throws -> OwnedAccountCredentialProofPrivateInputs {
        guard let identityObjectData = accountData.identityObjectJSON.data(using: .utf8) else {
            throw SessionRequstError.generic("Failed to convert identity object JSON to data")
        }
        let identityObject = try JSONDecoder().decode(Concordium.IdentityObject.self, from: identityObjectData)
        let attributeValues = try convertToAttributeValues(identityObject: identityObject)
        
        let attributeRandomness = try await getAttributeRandomness(
            encryptedCommitmentsRandomnessKey: accountData.encryptedCommitmentsRandomnessKey,
            password: password
        )
        
        return OwnedAccountCredentialProofPrivateInputs(
            issuer: UInt32(accountData.ipIdentity),
            attributeValues: attributeValues,
            attributeRandomness: attributeRandomness
        )
    }
    
    /// Note: The Swift SDK's createVerifiablePresentationV1 doesn't take providedContext directly
    /// We need to merge it into the request's context before calling the function
    private func buildProvidedContext(anchorBlockHash: String) throws -> [LabeledContextProperty] {
        var providedContext: [LabeledContextProperty] = []
        
        // For each requested context label, provide the value
        for requestedLabel in requestV1.context.requested {
            let contextLabel = try convertToContextLabel(requestedLabel.label)
            
            switch contextLabel {
            case .blockHash:
                guard let blockHashData = Data(hex: anchorBlockHash) else {
                    continue
                }
                providedContext.append(.blockHash(blockHash: Bytes(blockHashData)))
                
            case .resourceId:
                providedContext.append(.resourceId(resouceId: "(╬▔皿▔)╯📦 you're welcome"))
                
            default:
                break
            }
        }
        
        return providedContext
    }
    
    /// Convert LabeledContextProperty to ContextProperty
    private func convertToContextProperty(_ labeled: LabeledContextProperty) -> ContextProperty {
        switch labeled {
        case .nonce(let nonce):
            return ContextProperty(label: "Nonce", context: nonce.hexDescription)
        case .paymentHash(let paymentHash):
            return ContextProperty(label: "PaymentHash", context: paymentHash.hexDescription)
        case .blockHash(let blockHash):
            return ContextProperty(label: "BlockHash", context: blockHash.hexDescription)
        case .connectionId(let connectionId):
            return ContextProperty(label: "ConnectionId", context: connectionId)
        case .resourceId(let resourceId):
            return ContextProperty(label: "ResourceId", context: resourceId)
        case .contextString(let contextString):
            return ContextProperty(label: "ContextString", context: contextString)
        }
    }
    
    /// Merge provided context into request's given context
    /// This is needed because Swift SDK doesn't take providedContext as a separate parameter
    private func mergeProvidedContextIntoRequest(_ providedContext: [LabeledContextProperty]) -> RequestV1 {
        // Convert LabeledContextProperty to ContextProperty
        let providedContextProperties = providedContext.map { convertToContextProperty($0) }
        
        // Map provided context by (lowercased) label for easy lookup
        var providedByLabel: [String: ContextProperty] = [:]
        for prop in providedContextProperties {
            providedByLabel[prop.label.lowercased()] = prop
        }
        
        // Keep the original "given" context as-is. Provided context values are
        // meant to fill requested fields, not to be duplicated into given.
        let mergedGiven = requestV1.context.given
        
        // Also fill in "requested" contexts where we now have a value.
        // This ensures the resulting presentation JSON has non-empty context
        // for e.g. BlockHash, which verifiers use as the transaction hash.
        let mergedRequested = requestV1.context.requested.map { prop -> ContextProperty in
            let key = prop.label.lowercased()
            if prop.context.isEmpty, let provided = providedByLabel[key] {
                return ContextProperty(label: prop.label, context: provided.context)
            } else {
                return prop
            }
        }
        
        let mergedContext = ContextInformation(given: mergedGiven, requested: mergedRequested)
        return RequestV1(context: mergedContext, subjectClaims: requestV1.subjectClaims)
    }
    
    // MARK: - Helper Functions for Proof Input Creation
    
    private func convertToIdentityProviderInfo(ipInfo: IPInfoResponseElement) throws -> IdentityProviderInfo {
        let ipInfoData = ipInfo.ipInfo
        
        // Convert Description - iOS app uses "desc" field, crypto library uses "description"
        let description = ConcordiumWalletCrypto.Description(
            name: ipInfoData.ipDescription.name,
            url: ipInfoData.ipDescription.url,
            description: ipInfoData.ipDescription.desc
        )
        
        // Convert hex strings to Bytes
        guard let verifyKeyData = Data(hex: ipInfoData.ipVerifyKey) else {
            throw SessionRequstError.generic("Invalid ipVerifyKey hex string")
        }
        guard let cdiVerifyKeyData = Data(hex: ipInfoData.ipCdiVerifyKey) else {
            throw SessionRequstError.generic("Invalid ipCdiVerifyKey hex string")
        }
        
        return IdentityProviderInfo(
            identity: UInt32(ipInfoData.ipIdentity),
            description: description,
            verifyKey: Bytes(verifyKeyData),
            cdiVerifyKey: Bytes(cdiVerifyKeyData)
        )
    }
    
    private func convertToArInfos(ipInfo: IPInfo, arsInfosDict: [String: ArsInfo]) throws -> ArInfos {
        var anonymityRevokers: [UInt32: AnonymityRevokerInfo] = [:]
        
        for (_, arsInfo) in arsInfosDict {
            guard arsInfo.arIdentity > 0,
                  let arIdentity = UInt32(exactly: arsInfo.arIdentity) else {
                continue
            }
                        
            let description = ConcordiumWalletCrypto.Description(
                name: arsInfo.arDescription.name,
                url: arsInfo.arDescription.url,
                description: arsInfo.arDescription.desc
            )
            
            guard let publicKeyData = Data(hex: arsInfo.arPublicKey) else {
                continue
            }
            
            let anonymityRevokerInfo = AnonymityRevokerInfo(
                identity: arIdentity,
                description: description,
                publicKey: Bytes(publicKeyData)
            )
            
            anonymityRevokers[arIdentity] = anonymityRevokerInfo
        }
        
        return ArInfos(anonymityRevokers: anonymityRevokers)
    }
    
    private func createIdObjectUseData(
        idCredSec: Data,
        prfKey: Data,
        signatureBlindingRandomness: Data,
        identityObject: Concordium.IdentityObject
    ) throws -> IdObjectUseData {
        let credHolderInfo = CredentialHolderInfo(idCred: Bytes(idCredSec))
        
        let accCredentialInfo = AccCredentialInfo(
            credHolderInfo: credHolderInfo,
            prfKey: Bytes(prfKey)
        )
        
        return IdObjectUseData(
            aci: accCredentialInfo,
            randomness: Bytes(signatureBlindingRandomness)
        )
    }
    
    /// Convert IdentityObject to attribute values map
    private func convertToAttributeValues(identityObject: Concordium.IdentityObject) throws -> [AttributeTag: Web3IdAttribute] {
        var attributeValues: [AttributeTag: Web3IdAttribute] = [:]
        
        let chosenAttributes = identityObject.attributeList.chosenAttributes
        
        for (attributeTag, value) in chosenAttributes {
            if let stringValue = value as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withFullDate]
                if let date = formatter.date(from: stringValue) {
                    attributeValues[attributeTag] = .timestamp(value: date)
                } else {
                    attributeValues[attributeTag] = .string(value: stringValue)
                }
            } else if let numberValue = value as? NSNumber {
                attributeValues[attributeTag] = .numeric(value: numberValue.uint64Value)
            }
        }
        
        return attributeValues
    }
    
    private func getAttributeRandomness(
        encryptedCommitmentsRandomnessKey: String?,
        password: String
    ) async throws -> [AttributeTag: Bytes] {
        guard let commitmentsRandomnessKey = encryptedCommitmentsRandomnessKey else {
            throw SessionRequstError.generic("Account has no commitments randomness")
        }
        
        let commitmentsRandomness = try storageManager.getCommitmentsRandomness(key: commitmentsRandomnessKey, pwHash: password).get()
        
        var attributeRandomness: [AttributeTag: Bytes] = [:]
        for (key, hexString) in commitmentsRandomness.attributesRand {
            guard let attributeTag = AttributeTag(key) else { continue }
            guard let randomnessData = Data(hex: hexString) else { continue }
            attributeRandomness[attributeTag] = Bytes(randomnessData)
        }
        return attributeRandomness
    }
    
    
}
