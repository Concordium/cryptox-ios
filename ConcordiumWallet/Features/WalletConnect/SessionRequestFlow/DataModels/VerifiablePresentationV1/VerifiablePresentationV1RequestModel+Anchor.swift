import Foundation
import Concordium
import ConcordiumWalletCrypto
import SwiftCBOR

extension VerifiablePresentationV1RequestModel {
    func loadAnchorData() async {
        await MainActor.run {
            isLoadingAnchor = true
            anchorLoadError = nil
        }

        do {
            let globalContext = try await concordiumClient.nodeClient.cryptographicParameters(block: .lastFinal)
            let transactionRef = extractTransactionRef(from: requestV1)

            if let transactionRef = transactionRef {
                let (blockHash, anchorHash) = try await loadAnchorTransaction(transactionRef: transactionRef)
                try verifyAnchor(anchorHash: anchorHash)

                await MainActor.run {
                    self.globalContext = globalContext
                    self.anchorBlockHash = blockHash
                    isLoadingAnchor = false
                }
            } else {
                await MainActor.run {
                    anchorLoadError = "Transaction reference not found in request"
                    isLoadingAnchor = false
                }
            }
        } catch {
            LegacyLogger.error("Error in loadAnchorData: \(error)")
            LegacyLogger.error("Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                LegacyLogger.error("NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")
            }
            await MainActor.run {
                anchorLoadError = error.localizedDescription
                isLoadingAnchor = false
            }
        }
    }

    private func extractTransactionRef(from request: RequestV1) -> String? {
        if let transactionRef = transactionRef {
            return transactionRef
        }

        for requested in request.context.requested {
            if requested.label.lowercased() == "blockhash" || requested.label.lowercased() == "transactionref" {
                return requested.context
            }
        }
        return nil
    }

    private func loadAnchorTransaction(transactionRef: String) async throws -> (blockHash: String, anchorHash: Bytes) {
        LegacyLogger.debug("Starting to load anchor transaction for transactionRef: \(transactionRef)")

        let maxRetries = 10
        var requestAnchorTransaction: SubmissionStatusJSON?

        for attempt in 1...maxRetries {
            do {
                LegacyLogger.debug("Attempt #\(attempt) to get the anchor transaction")
                let status = try await concordiumClient.getSubmissionStatus(transactionRef: transactionRef)

                if let blockHashes = status.blockHashes, !blockHashes.isEmpty {
                    requestAnchorTransaction = status
                    LegacyLogger.debug("Successfully loaded anchor transaction on attempt #\(attempt)")
                    break
                } else {
                    LegacyLogger.debug("Transaction not yet included in block, retrying...")
                }
            } catch {
                LegacyLogger.debug("Failed to load submission status on attempt #\(attempt): \(error.localizedDescription). Retrying...")
            }

            if attempt < maxRetries {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        guard let status = requestAnchorTransaction else {
            LegacyLogger.error("Failed getting anchor transaction block hash in time after \(maxRetries) attempts")
            throw SessionRequstError.generic("Failed getting anchor transaction block hash in time")
        }

        guard let blockHash = status.blockHashes?.first else {
            LegacyLogger.error("No block hash found in submission status")
            throw SessionRequstError.generic("No block hash found in submission status")
        }

        guard let anchorCborHex = status.registeredData else {
            LegacyLogger.error("Anchor transaction data is missing from submission status")
            throw SessionRequstError.generic("Anchor transaction data is missing")
        }

        guard let anchorCborData = Data(hex: anchorCborHex) else {
            LegacyLogger.error("Failed to decode anchor CBOR hex string: \(anchorCborHex)")
            throw SessionRequstError.generic("Failed to decode anchor CBOR hex string")
        }

        let anchorHash = try decodeAnchorHash(from: anchorCborData)
        LegacyLogger.debug("Successfully loaded and decoded anchor transaction - blockHash: \(blockHash), anchorHash: \(anchorHash.hexDescription)")

        return (blockHash: blockHash, anchorHash: anchorHash)
    }

    private func decodeAnchorHash(from cborData: Data) throws -> Bytes {
        guard let cbor = try? CBOR.decode(Array(cborData)) else {
            throw SessionRequstError.generic("Failed to decode anchor CBOR")
        }

        guard case .map(let map) = cbor else {
            throw SessionRequstError.generic("Anchor CBOR is not a map")
        }

        let hashKey = CBOR.utf8String("hash")
        guard let hashValue = map[hashKey] else {
            throw SessionRequstError.generic("Hash not found in anchor CBOR")
        }

        guard case .byteString(let hashBytes) = hashValue else {
            throw SessionRequstError.generic("Hash value is not a byte string")
        }

        return Data(hashBytes)
    }

    private func verifyAnchor(anchorHash: Bytes) throws {
        LegacyLogger.debug("Starting anchor verification")

        let verificationRequestData = try convertToVerificationRequestData(requestV1)
        LegacyLogger.debug("Converted RequestV1 to VerificationRequestData - given: \(verificationRequestData.context.given.count) items, requested: \(verificationRequestData.context.requested.count) items, subjectClaims: \(verificationRequestData.subjectClaims.count) items")

        LegacyLogger.debug("Calling computeAnchorHash...")
        do {
            let computedHash = try computeAnchorHash(verificationRequestData: verificationRequestData)
            LegacyLogger.debug("Computed anchor hash: \(computedHash.hexDescription)")
            LegacyLogger.debug("Anchor hash from transaction: \(anchorHash.hexDescription)")

            guard computedHash == anchorHash else {
                LegacyLogger.error("Anchor verification failed - computed hash (\(computedHash.hexDescription)) does not match anchor hash (\(anchorHash.hexDescription))")
                throw SessionRequstError.generic("Anchor doesn't match the request")
            }

            LegacyLogger.debug("Anchor verification successful")
        } catch {
            LegacyLogger.error("Error computing anchor hash: \(error)")
            LegacyLogger.error("Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                LegacyLogger.error("NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }

    private func convertToVerificationRequestData(_ request: RequestV1) throws -> VerificationRequestData {
        LegacyLogger.debug("Converting RequestV1 to VerificationRequestData")
        LegacyLogger.debug("Request context - given: \(request.context.given.count) items, requested: \(request.context.requested.count) items")
        LegacyLogger.debug("Request subjectClaims: \(request.subjectClaims.count) items")

        let given = try request.context.given.map { prop in
            let converted = try convertToLabeledContextProperty(prop)
            LegacyLogger.debug("Converted given context property - label: \(prop.label), type: \(String(describing: converted))")
            return converted
        }

        let requested = try request.context.requested.map { prop in
            let label = try convertToContextLabel(prop.label)
            LegacyLogger.debug("Converted requested context label - original: \(prop.label), converted: \(String(describing: label))")
            return label
        }

        let unfilledContext = UnfilledContextInformation(given: given, requested: requested)

        let requestedSubjectClaims = try request.subjectClaims.enumerated().map { index, claim in
            let converted = try convertToRequestedSubjectClaims(claim, claimIndex: index)
            LegacyLogger.debug("Converted subject claim #\(index) - type: \(String(describing: converted))")
            return converted
        }

        LegacyLogger.debug("Successfully converted RequestV1 to VerificationRequestData")
        return VerificationRequestData(context: unfilledContext, subjectClaims: requestedSubjectClaims)
    }

    private func convertToLabeledContextProperty(_ prop: ContextProperty) throws -> LabeledContextProperty {
        let labelLower = prop.label.lowercased()

        switch labelLower {
        case "nonce":
            guard let nonceData = Data(hex: prop.context) else {
                throw SessionRequstError.generic("Invalid nonce hex string")
            }
            return .nonce(nonce: nonceData)
        case "paymenthash", "payment_hash":
            guard let paymentHashData = Data(hex: prop.context) else {
                throw SessionRequstError.generic("Invalid payment hash hex string")
            }
            return .paymentHash(paymentHash: paymentHashData)
        case "blockhash", "block_hash":
            guard let blockHashData = Data(hex: prop.context) else {
                throw SessionRequstError.generic("Invalid block hash hex string")
            }
            return .blockHash(blockHash: blockHashData)
        case "connectionid", "connection_id":
            return .connectionId(connectionId: prop.context)
        case "resourceid", "resource_id":
            return .resourceId(resouceId: prop.context)
        case "contextstring", "context_string":
            return .contextString(contextString: prop.context)
        default:
            if let hexData = Data(hex: prop.context), hexData.count == 32 {
                return .nonce(nonce: hexData)
            } else {
                return .contextString(contextString: prop.context)
            }
        }
    }

    func convertToContextLabel(_ label: String) throws -> ContextLabel {
        let labelLower = label.lowercased()

        switch labelLower {
        case "nonce":
            return .nonce
        case "paymenthash", "payment_hash":
            return .paymentHash
        case "blockhash", "block_hash":
            return .blockHash
        case "connectionid", "connection_id":
            return .connectionId
        case "resourceid", "resource_id":
            return .resourceId
        case "contextstring", "context_string":
            return .contextString
        default:
            throw SessionRequstError.generic("Unknown context label: \(label)")
        }
    }

    private func convertToRequestedSubjectClaims(_ claim: SubjectClaims, claimIndex: Int) throws -> RequestedSubjectClaims {
        guard let subjectClaimsArray = originalRequestJSON["subjectClaims"] as? [[String: Any]],
              claimIndex < subjectClaimsArray.count else {
            throw SessionRequstError.generic("Cannot find subject claim in original JSON")
        }

        let claimDict = subjectClaimsArray[claimIndex]

        let source: [IdentityCredentialType]
        if let sourceArray = claimDict["source"] as? [String] {
            source = sourceArray.compactMap { sourceString in
                switch sourceString {
                case "identityCredential": return .identityCredential
                case "accountCredential": return .accountCredential
                default: return nil
                }
            }
        } else {
            switch claim {
            case .identity: source = [.identityCredential, .accountCredential]
            case .account: source = [.accountCredential]
            }
        }

        let issuers: [IdentityProviderDid]
        if let issuersArray = claimDict["issuers"] as? [Any] {
            issuers = try issuersArray.compactMap { issuerValue -> IdentityProviderDid? in
                guard let issuerString = issuerValue as? String else { return nil }
                guard issuerString.hasPrefix("did:ccd:") else { return nil }
                let parts = issuerString.split(separator: ":")
                guard parts.count >= 5 else { return nil }
                let networkString = String(parts[2]).lowercased()
                let idpPart = String(parts[4])
                guard let idpUInt = UInt32(idpPart) else {
                    return nil
                }

                let network: Network = networkString == "testnet" ? .testnet : .mainnet
                return IdentityProviderDid(network: network, identityProvider: idpUInt)
            }
        } else if let issuerValue = claimDict["issuer"] {
            let issuerDid: IdentityProviderDid
            switch claim {
            case .identity(let identityClaims):
                issuerDid = IdentityProviderDid(
                    network: identityClaims.network,
                    identityProvider: identityClaims.issuer
                )
            case .account(let accountClaims):
                issuerDid = IdentityProviderDid(
                    network: accountClaims.network,
                    identityProvider: accountClaims.issuer
                )
            }
            issuers = [issuerDid]
        } else {
            throw SessionRequstError.generic("No issuers found in subject claim")
        }

        guard !issuers.isEmpty else {
            throw SessionRequstError.generic("No valid issuers found")
        }

        let statements: [AtomicStatementV1]
        switch claim {
        case .identity(let identityClaims):
            statements = identityClaims.statements
        case .account(let accountClaims):
            statements = accountClaims.statements
        }

        let requestedStatements = try statements.map { statement in
            try convertToRequestedStatement(statement)
        }

        let requestedIdentityClaims = RequestedIdentitySubjectClaims(
            statements: requestedStatements,
            issuers: issuers,
            source: source
        )

        return .identity(identity: requestedIdentityClaims)
    }

    private func convertToRequestedStatement(_ statement: AtomicStatementV1) throws -> RequestedStatement {
        switch statement {
        case .attributeValue(let s):
            let revealStatement = RevealAttributeIdentityStatement(attributeTag: s.attributeTag)
            return .revealAttribute(statement: revealStatement)
        case .attributeInRange(let s):
            return .attributeInRange(statement: s)
        case .attributeInSet(let s):
            return .attributeInSet(statement: s)
        case .attributeNotInSet(let s):
            return .attributeNotInSet(statement: s)
        }
    }
}

