//
//  VerifiablePresentationRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 19.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import ReownWalletKit
import WalletConnectVerify
import Combine
import Concordium

protocol VerifiableStatementsPresentation {
//    var credentialStatements: [VerifiablePresentationStatements] { get }
    var credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement] { get }
}

enum VerifiableStatementError {
    case invalidIdentity
    case invalidStatement
    
    var description: String {
        switch self {
            case .invalidIdentity:
                return "unable_to_prove_request".localized
            case .invalidStatement:
                return "unable_to_prove_request".localized
        }
    }
}

final class VerifiablePresentationRequestModel: ObservableObject, SessionRequestDataProvidable, VerifiableStatementsPresentation {
    @Published var title: String = "Proof Request"
    
    @Published var credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement]//[VerifiablePresentationStatements]
    
    @Published var error: VerifiableStatementError?
    
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let payload: WalletConnectRequestVerifiablePresentationParam
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let concordiumClient: ConcordiumClient
    private let identitiesService: SeedIdentitiesService
    
    private var verifiablePresentationBuilder: VerifiablePresentationBuilder

    init(
        payload: WalletConnectRequestVerifiablePresentationParam,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService
    ) {
        self.sessionRequest = sessionRequest
        self.payload = payload
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        
        self.credentialStatements = payload.credentialStatements
        self.identitiesService = identitiesService

        self.concordiumClient = concordiumClient
        
        self.verifiablePresentationBuilder = VerifiablePresentationBuilder(
            challenge: payload.challenge,
            network: ConcordiumClient.network
        )
        
        let isValidIdentity: Bool = payload.credentialStatements
            .map { credentialStatement -> [UInt32] in
                switch credentialStatement {
                case .account(let issuers, statement: _): return issuers
                case .web3id(let issuers, statement: _): return []
                }
            }
            .map { issuers -> Bool in
                guard let ipIdentity = account.identity?.identityProvider?.ipInfo?.ipIdentity else { return false }
                return issuers.contains(where: { $0 == ipIdentity })
            }.contains(true)
        
        
        if isValidIdentity == false {
            error = .invalidIdentity
        }
        
        if !Self.validateCredentialStatements(payload.credentialStatements, account: account) {
            error = .invalidStatement
        }
    }
    
    static func validateCredentialStatements(
        _ credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement],
        account: AccountEntity
    ) -> Bool {
        credentialStatements
            .flatMap { credentialStatement in
                switch credentialStatement {
                case let .account(_, statement): return statement
                case let .web3id(issuers, statement): return []
                }
            }
            .contains(where: { isValidStatement($0, account: account) })
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        return error == nil
    }
    
    @MainActor
    func approveRequest() async throws {
        guard statements().isEmpty == false else { return }
        
        let pass = try await passwordDelegate.requestUserPassword(keychain: KeychainWrapper())

        let (seed, proof): (String, IdentityProof) = try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let phrase = try await identitiesService.mobileWallet.getRecoveryPhrase(pwHash: pass)
                    let seed = phrase.joined(separator: " ")

                    let proof = try await concordiumClient.proveStatements(
                        statements: statements(),
                        seedPhrase: seed,
                        account: account
                    )

                    continuation.resume(returning: (seed, proof))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let walletSeed = try Helper.decodeSeed(seed, ConcordiumClient.network)
        let cryptoParams = try await concordiumClient.nodeClient.cryptographicParameters(block: .lastFinal)
        let credentialIndices = AccountCredentialSeedIndexes(
            identity: IdentitySeedIndexes(
                providerID: IdentityProviderID(account.identity?.identityProvider?.ipInfo?.ipIdentity ?? 0),
                index: IdentityIndex(account.identity?.index ?? 0)),
            counter: CredentialCounter(account.identityEntity?.accountsCreated ?? 0)
        )
        
        guard let identityObjectApp = account.identityEntity?.seedIdentityObject else { throw GeneralAppError.somethingWentWrong }
        
        guard let data = try identityObjectApp.json().data(using: .utf8) else { throw GeneralAppError.somethingWentWrong }
        
        let identityObject = try JSONDecoder().decode(Concordium.IdentityObject.self, from: data)
            

        try verifiablePresentationBuilder
            .verify(statements(),
                    for: identityObject.attributeList.chosenAttributes,
                    wallet: walletSeed,
                    credIndices: credentialIndices,
                    global: cryptoParams
            )
        
        

        let finalized: VerifiablePresentation = try verifiablePresentationBuilder.finalize(global: cryptoParams)

        let wrapped = try VerifiableJSON(verifiablePresentationJson: finalized).wrappedAsDictionary()

        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(wrapped))
        )
    }

    
    private func statements() -> [AtomicIdentityStatement] {
        credentialStatements
            .flatMap { credentialStatement in
                switch credentialStatement {
                case let .account(_, statement): return statement
                case .web3id: return []
                }
            }
            .compactMap { $0 }
    }
}

extension Date {
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}

extension VerifiablePresentationRequestModel {
    func getStatementCellModels() -> [VerifiableStatementListCellModel] {
        credentialStatements.flatMap { credentialStatement in
            switch credentialStatement {
            case .account(_, let statements):
                return statements.map(getModel(_:))
            case .web3id:
                return []
            }
        }
    }
    
    private func getModel(_ statement: AtomicIdentityStatement) -> VerifiableStatementListCellModel {
        VerifiableStatementListCellModel(
            title: statement.attributeTag.localizedKey,
            value: Self.valueData(for: statement, account: account) ?? "No Data",
            description: "reveal_description".localized,
            isValid: Self.isValidStatement(statement, account: account)
        )
    }
    
    static func valueData(for statement: AtomicIdentityStatement, account: AccountEntity) -> String? {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]

        switch statement {
        case .revealAttribute(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeInSet(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeNotInSet(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeInRange(let inner):
            let tag = inner.attributeTag
            let today = Calendar.current.startOfDay(for: Date())

            guard let lowerDate = Date.initWithFormat(with: inner.lower),
                  let upperDate = Date.initWithFormat(with: inner.upper) else {
                return nil
            }

            if tag == .dateOfBirth {
                return upperDate > today
                    ? "identity_proofs_age_min".localized("\(yearsBetweenDates(startDate: today, endDate: lowerDate))")
                    : "identity_proofs_age_max".localized("\(yearsBetweenDates(startDate: today, endDate: upperDate))")
            } else {
                let raw = attributes["\(tag.rawValue)"] ?? ""
                return tag.formattedValue(raw)
            }
        }
    }


    static func isValidStatement(_ statement: AtomicIdentityStatement, account: AccountEntity) -> Bool {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]

        switch statement {
        case .revealAttribute(let inner):
            return attributes["\(inner.attributeTag)"] != nil

        case .attributeInSet(let inner):
            let value = attributes["\(inner.attributeTag)"] ?? ""
            return inner.set.contains(value)

        case .attributeNotInSet(let inner):
            let value = attributes["\(inner.attributeTag)"] ?? ""
            return !inner.set.contains(value)

        case .attributeInRange(let inner):
            let tag = inner.attributeTag
            let rawValue = attributes["\(tag)"] ?? ""

            switch tag {
            case .dateOfBirth, .idDocIssuedAt, .idDocExpiresAt:
                guard let valueDate = Date.initWithFormat(with: rawValue),
                      let lowerDate = Date.initWithFormat(with: inner.lower),
                      let upperDate = Date.initWithFormat(with: inner.upper)
                else {
                    return false
                }
                return (lowerDate...upperDate).contains(valueDate)

            default:
                let valueDecimal = Decimal(string: rawValue) ?? .zero
                let lower = Decimal(string: inner.lower) ?? .zero
                let upper = Decimal(string: inner.upper) ?? .zero
                return (lower...upper).contains(valueDecimal)
            }
        }
    }


}








struct VerifiableStatementListCellModel {
    let title: String
    let value: String
    let description: String
    let isValid: Bool
}


extension VerifiablePresentationRequestModel {
//    func getModel(for statement: VerifiablePresentationStatement) -> VerifiableStatementListCellModel {
//        VerifiableStatementListCellModel(
//            title: AttributeFormatter.format(key: statement.attributeTag),
//            value: Self.valueData(for: statement, account: account) ?? "no data",
//            description: "reveal_description".localized,
//            isValid: Self.isValidStatement(statement, account: account)
//        )
//    }
//    
//    static func valueData(for statement: VerifiablePresentationStatement, account: AccountEntity) -> String? {
//        switch statement.attributeTag {
//            case .dob:
//                let currentDateTimeless = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: Date())) ?? Date()
//                if statement.upperAsDate > Date() {
//                    return "identity_proofs_age_min".localized("\(Self.yearsBetweenDates(startDate: currentDateTimeless, endDate: statement.lowerAsDate))")
//                } else {
//                    return "identity_proofs_age_max".localized("\(Self.yearsBetweenDates(startDate: currentDateTimeless, endDate: statement.upperAsDate))")
//                }
//            case .firstName, .lastName:
//                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue]
//            case .sex:
//                return "fix me - sex"
//            case .countryOfResidence:
//                return "fix me - countryOfResidence"
//            case .nationality:
//                return "fix me - nationality"
//            case .idDocType:
//                return "fix me - idDocType"
//            case .idDocNo:
//                return "fix me - idDocNo"
//            case .idDocIssuer:
//                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue]
//            case .idDocIssuedAt:
//                return "fix me - idDocIssuedAt"
//            case .idDocExpiresAt:
//                return "fix me - idDocExpiresAt"
//            case .nationalIdNo:
//                return "fix me - nationalIdNo"
//            case .taxIdNo:
//                return "fix me - taxIdNo"
//        default: return "fix me - \(statement.attributeTag)"
//        }
//    }
    
//    static func isValidStatement(_ statement: VerifiablePresentationStatement, account: AccountEntity) -> Bool {
//        switch statement.type {
//            case .revealAttribute:
//                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue] != nil
//            case .attributeInSet:
//                guard let set = statement.set else { return false }
//                guard let value = valueData(for: statement, account: account) else { return false }
//                return set.contains(where: { $0 == value })
//            case .attributeNotInSet: return false
//            case .attributeInRange:
//                let value = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue] ?? ""
//
//                switch statement.attributeTag {
//                    case .dob, .idDocExpiresAt, .idDocIssuedAt:
//                        // due to api returns value for range min and max values in strange way (ISO 8601) as dates: `"18000101"` in format `"yyyyMMdd"`
//                        // we cant simply constract an range
//                        return (statement.lowerAsDate...statement.upperAsDate).contains(Date.initWithFormat(with: value) ?? Date())
//                    default:
//                        return Range(uncheckedBounds: (lower: Decimal(string: statement.lower ?? "") ?? .zero, upper: Decimal(string: statement.upper ?? "") ?? .zero)).contains(Decimal(string: value) ?? .zero)
//                }
//        }
//    }
    
    static func yearsBetweenDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        return max(0, startYear - endYear)
    }
}

extension Date {
    static func initWithFormat(with dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: dateString)
    }
}






import Foundation
import Concordium

extension Concordium.AttributeTag {
    public var localizedKey: String {
        switch self {
            case .firstName: return "attributes.firstName".localized
            case .lastName: return "attributes.lastName".localized
            case .sex: return "attributes.sex".localized
            case .dateOfBirth: return "attributes.dob".localized
            case .countryOfResidence: return "attributes.countryOfResidence".localized
            case .nationality: return "attributes.nationality".localized
            case .idDocType: return "attributes.idDocType".localized
            case .idDocNo: return "attributes.idDocNo".localized
            case .idDocIssuer: return "attributes.idDocIssuer".localized
            case .idDocIssuedAt: return "attributes.idDocIssuedAt".localized
            case .idDocExpiresAt: return "attributes.idDocExpiresAt".localized
            case .nationalIdNo: return "attributes.nationalIDNo".localized
            case .taxIdNo: return "attributes.taxIDNo".localized
            case .legalEntityId: return "attributes.lei".localized
            case .legalName: return "attributes.legalName".localized
            case .legalCountry: return "attributes.legalCountry".localized
            case .businessNumber: return "attributes.businessNumber".localized
            case .registrationAuth: return "attributes.registrationAuth".localized
        }
    }

    public func formattedValue(_ value: String) -> String {
        let formatter = InternalFormatter()

        switch self {
            case .firstName, .lastName, .legalName, .registrationAuth:
                return formatter.format(name: value)

            case .idDocNo, .nationalIdNo, .taxIdNo, .businessNumber:
                return formatter.format(plainNumber: value)

            case .dateOfBirth:
                return formatter.format(dateOfBirth: value)

            case .idDocIssuedAt, .idDocExpiresAt:
                return formatter.format(date: value)

            case .countryOfResidence, .nationality, .idDocIssuer, .legalCountry:
                return formatter.format(countryCode: value)

            case .sex:
                return formatter.format(sex: value)

            case .idDocType:
                return formatter.format(documentType: value)

            case .legalEntityId:
                return formatter.formatLei(lei: value)
        }
    }
}

private class InternalFormatter {
    func format(name: String) -> String {
        name
    }
    
    func format(plainNumber: String) -> String {
        plainNumber
    }
    
    func format(dateOfBirth: String) -> String {
        GeneralFormatter.formatISO8601Date(date: dateOfBirth, hasDay: true, outputFormat: "dd MMMM, yyyy")
    }
    
    func format(date: String) -> String {
        GeneralFormatter.formatISO8601Date(date: date, hasDay: true)
    }
    
    func format(countryCode: String) -> String {
        countryName(for: countryCode)
    }
    
    func format(sex: String) -> String {
        guard let sexEnum = Sex(rawValue: sex) else {
            return "sex.notKnown".localized
        }
        switch sexEnum {
            case .male:
                return "Male".localized
            case .female:
                return "Female".localized
            default:
                return "sex.notKnown".localized
        }
    }
    
    func format(documentType: String) -> String {
        guard let documentTypeEnum = DocumentType(rawValue: documentType) else {
            return ""
        }
        var formattedDocumentType = ""
        switch documentTypeEnum {
            case .na:
                formattedDocumentType = "Not applicable".localized
            case .drivingLicense:
                formattedDocumentType = "Driving License".localized
            case .ImmigrationCard:
                formattedDocumentType = "Immigration Card".localized
            case .nationalIDCard:
                formattedDocumentType = "National ID".localized
            case .passport:
                formattedDocumentType = "Passport".localized
        }
        return formattedDocumentType
    }
    
    func countryName(for countryCode: String) -> String {
        var countryName = ""
        //What locale should we use ??
        let locale = NSLocale.current
        let identifier = NSLocale(localeIdentifier: locale.identifier)
        countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: countryCode) ?? ""
        return countryName
    }
    
    func formatLei(lei: String) -> String {
        if lei.isEmpty {
            return "unavailable".localized
        } else {
            return lei
        }
    }
}



struct VerifiableJSON: Codable {
    let verifiablePresentationJson: VerifiablePresentation
}

extension VerifiableJSON {
    /// Returns a dictionary where `verifiablePresentationJson` is a stringified JSON (not an object)
    func wrappedAsDictionary() throws -> [String: String] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let innerData = try encoder.encode(verifiablePresentationJson)
        guard let innerJSONString = String(data: innerData, encoding: .utf8) else {
            throw NSError(domain: "VerifiableJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to encode inner presentation"])
        }

        return ["verifiablePresentationJson": innerJSONString]
    }
}
