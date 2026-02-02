//
//  RequestV1Decoder.swift
//  Concrodium

import Foundation
import ConcordiumWalletCrypto
import Concordium

/// Helper to decode RequestV1 from JSON data
enum RequestV1Decoder {
    static func decode(from data: Data) throws -> (RequestV1, transactionRef: String?) {
        // Decode into a dictionary first to manually construct RequestV1
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json = json else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        // Decode context
        guard let contextDict = json["context"] as? [String: Any] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        let given = (contextDict["given"] as? [[String: Any]] ?? []).compactMap { dict -> ContextProperty? in
            guard let label = dict["label"] as? String,
                  let context = dict["context"] as? String else {
                return nil
            }
            return ContextProperty(label: label, context: context)
        }
        
        // Requested can be an array of strings (labels) or array of objects
        var requested: [ContextProperty] = []
        if let requestedArray = contextDict["requested"] as? [String] {
            // Array of strings - these are just labels, context will be filled later
            requested = requestedArray.map { label in
                ContextProperty(label: label, context: "")
            }
        } else if let requestedArray = contextDict["requested"] as? [[String: Any]] {
            // Array of objects with label and context
            requested = requestedArray.compactMap { dict -> ContextProperty? in
                guard let label = dict["label"] as? String,
                      let context = dict["context"] as? String else {
                    return nil
                }
                return ContextProperty(label: label, context: context)
            }
        }
        
        let context = ContextInformation(given: given, requested: requested)
        
        // Decode subjectClaims
        guard let subjectClaimsArray = json["subjectClaims"] as? [[String: Any]] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        let subjectClaims: [SubjectClaims] = try subjectClaimsArray.map { claimDict in
            // Check if it's account or identity based
            // The structure might have "type" field indicating the type
            if let type = claimDict["type"] as? String, type == "account" {
                // Account-based claims
                return try decodeAccountBasedSubjectClaims(from: claimDict)
            } else if let type = claimDict["type"] as? String, type == "identity" {
                // Identity-based claims
                return try decodeIdentityBasedSubjectClaims(from: claimDict)
            } else if claimDict["account"] != nil {
                // Legacy format with nested "account" key
                if let accountDict = claimDict["account"] as? [String: Any] {
                    return try decodeAccountBasedSubjectClaims(from: accountDict)
                } else {
                    return try decodeAccountBasedSubjectClaims(from: claimDict)
                }
            } else if claimDict["identity"] != nil {
                // Legacy format with nested "identity" key
                if let identityDict = claimDict["identity"] as? [String: Any] {
                    return try decodeIdentityBasedSubjectClaims(from: identityDict)
                } else {
                    return try decodeIdentityBasedSubjectClaims(from: claimDict)
                }
            } else {
                throw SessionRequstError.unSupportedRequestMethod
            }
        }
        
        // Extract transactionRef from root if present
        let transactionRef = json["transactionRef"] as? String
        
        let requestV1 = RequestV1(context: context, subjectClaims: subjectClaims)
        return (requestV1, transactionRef: transactionRef)
    }
    
    private static func decodeAccountBasedSubjectClaims(from dict: [String: Any]) throws -> SubjectClaims {
        // Decode network - might be in "network" field or inferred
        let network: Network
        if let networkString = dict["network"] as? String {
            network = networkString.lowercased() == "testnet" ? .testnet : .mainnet
        } else {
            // Default to current network
            network = ConcordiumClient.network == .testnet ? .testnet : .mainnet
        }
        
        // Decode issuer - might be "issuer" (single) or "issuers" (array)
        guard let issuerValue = dict["issuer"] ?? dict["issuers"] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let issuer: UInt32
        if let issuerArray = issuerValue as? [Any], let firstIssuer = issuerArray.first {
            // Array of issuers - take the first one
            if let issuerInt = firstIssuer as? UInt32 {
                issuer = issuerInt
            } else if let issuerString = firstIssuer as? String {
                // Might be a DID string like "did:ccd:testnet:idp:0"
                if issuerString.hasPrefix("did:ccd:"), let idpPart = issuerString.split(separator: ":").last, let idpUInt = UInt32(idpPart) {
                    issuer = idpUInt
                } else if let issuerUInt = UInt32(issuerString) {
                    issuer = issuerUInt
                } else {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            } else if let issuerNum = firstIssuer as? NSNumber {
                issuer = issuerNum.uint32Value
            } else {
                throw SessionRequstError.unSupportedRequestMethod
            }
        } else if let issuerInt = issuerValue as? UInt32 {
            issuer = issuerInt
        } else if let issuerString = issuerValue as? String {
            // Might be a DID string like "did:ccd:testnet:idp:0"
            if issuerString.hasPrefix("did:ccd:"), let idpPart = issuerString.split(separator: ":").last, let idpUInt = UInt32(idpPart) {
                issuer = idpUInt
            } else if let issuerUInt = UInt32(issuerString) {
                issuer = issuerUInt
            } else {
                throw SessionRequstError.unSupportedRequestMethod
            }
        } else if let issuerNum = issuerValue as? NSNumber {
            issuer = issuerNum.uint32Value
        } else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        // Decode credId (Bytes = Data, typically hex string in JSON)
        guard let credIdValue = dict["credId"] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let credId: Bytes
        if let credIdString = credIdValue as? String {
            // Try to decode as hex string
            guard let credIdData = Data(hexString: credIdString) else {
                throw SessionRequstError.unSupportedRequestMethod
            }
            credId = credIdData
        } else if let credIdArray = credIdValue as? [UInt8] {
            credId = Data(credIdArray)
        } else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        // Decode statements
        guard let statementsArray = dict["statements"] as? [[String: Any]] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let statements = try statementsArray.map { try decodeAtomicStatementV1(from: $0) }
        
        let accountClaims = AccountBasedSubjectClaims(
            network: network,
            issuer: issuer,
            credId: credId,
            statements: statements
        )
        
        return .account(account: accountClaims)
    }
    
    private static func decodeIdentityBasedSubjectClaims(from dict: [String: Any]) throws -> SubjectClaims {
        // Decode network - might be in "network" field or inferred
        let network: Network
        if let networkString = dict["network"] as? String {
            network = networkString.lowercased() == "testnet" ? .testnet : .mainnet
        } else {
            // Default to current network
            network = ConcordiumClient.network == .testnet ? .testnet : .mainnet
        }
        
        // Decode issuer - might be "issuer" (single) or "issuers" (array)
        guard let issuerValue = dict["issuer"] ?? dict["issuers"] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let issuer: UInt32
        if let issuerArray = issuerValue as? [Any], let firstIssuer = issuerArray.first {
            // Array of issuers - take the first one
            if let issuerInt = firstIssuer as? UInt32 {
                issuer = issuerInt
            } else if let issuerString = firstIssuer as? String {
                // Might be a DID string like "did:ccd:testnet:idp:0"
                if issuerString.hasPrefix("did:ccd:"), let idpPart = issuerString.split(separator: ":").last, let idpUInt = UInt32(idpPart) {
                    issuer = idpUInt
                } else if let issuerUInt = UInt32(issuerString) {
                    issuer = issuerUInt
                } else {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            } else if let issuerNum = firstIssuer as? NSNumber {
                issuer = issuerNum.uint32Value
            } else {
                throw SessionRequstError.unSupportedRequestMethod
            }
        } else if let issuerInt = issuerValue as? UInt32 {
            issuer = issuerInt
        } else if let issuerString = issuerValue as? String {
            // Might be a DID string like "did:ccd:testnet:idp:0"
            if issuerString.hasPrefix("did:ccd:"), let idpPart = issuerString.split(separator: ":").last, let idpUInt = UInt32(idpPart) {
                issuer = idpUInt
            } else if let issuerUInt = UInt32(issuerString) {
                issuer = issuerUInt
            } else {
                throw SessionRequstError.unSupportedRequestMethod
            }
        } else if let issuerNum = issuerValue as? NSNumber {
            issuer = issuerNum.uint32Value
        } else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        // Decode statements
        guard let statementsArray = dict["statements"] as? [[String: Any]] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let statements = try statementsArray.map { try decodeAtomicStatementV1(from: $0) }
        
        let identityClaims = IdentityBasedSubjectClaims(
            network: network,
            issuer: issuer,
            statements: statements
        )
        
        return .identity(identity: identityClaims)
    }
    
    private static func decodeAtomicStatementV1(from dict: [String: Any]) throws -> AtomicStatementV1 {
        guard let typeString = dict["type"] as? String else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        switch typeString {
        case "AttributeValue", "RevealAttribute":
            return try decodeAttributeValueStatement(from: dict)
        case "AttributeInRange":
            return try decodeAttributeInRangeStatement(from: dict)
        case "AttributeInSet":
            return try decodeAttributeInSetStatement(from: dict)
        case "AttributeNotInSet":
            return try decodeAttributeNotInSetStatement(from: dict)
        default:
            throw SessionRequstError.unSupportedRequestMethod
        }
    }
    
    private static func decodeAttributeValueStatement(from dict: [String: Any]) throws -> AtomicStatementV1 {
        guard let attributeTagString = dict["attributeTag"] as? String else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let attributeTag = try decodeAttributeTag(from: attributeTagString)
        
        // Decode attributeValue (Web3IdAttribute)
        // For now, we'll need to decode this as a string or number
        // Web3IdAttribute is complex - this is a simplified version
        let attributeValue = try decodeWeb3IdAttribute(from: dict["attributeValue"])
        
        let statement = AttributeValueIdentityStatementV1(
            attributeTag: attributeTag,
            attributeValue: attributeValue
        )
        
        return .attributeValue(statement: statement)
    }
    
    private static func decodeAttributeInRangeStatement(from dict: [String: Any]) throws -> AtomicStatementV1 {
        guard let attributeTagString = dict["attributeTag"] as? String else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let attributeTag = try decodeAttributeTag(from: attributeTagString)
        
        let lower = try decodeWeb3IdAttribute(from: dict["lower"])
        let upper = try decodeWeb3IdAttribute(from: dict["upper"])
        
        let statement = AttributeInRangeIdentityStatementV1(
            attributeTag: attributeTag,
            lower: lower,
            upper: upper
        )
        
        return .attributeInRange(statement: statement)
    }
    
    private static func decodeAttributeInSetStatement(from dict: [String: Any]) throws -> AtomicStatementV1 {
        guard let attributeTagString = dict["attributeTag"] as? String else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let attributeTag = try decodeAttributeTag(from: attributeTagString)
        
        guard let setArray = dict["set"] as? [Any] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        let set = try setArray.map { try decodeWeb3IdAttribute(from: $0) }
        
        let statement = AttributeInSetIdentityStatementV1(
            attributeTag: attributeTag,
            set: set
        )
        
        return .attributeInSet(statement: statement)
    }
    
    private static func decodeAttributeNotInSetStatement(from dict: [String: Any]) throws -> AtomicStatementV1 {
        guard let attributeTagString = dict["attributeTag"] as? String else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        let attributeTag = try decodeAttributeTag(from: attributeTagString)
        
        guard let setArray = dict["set"] as? [Any] else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        let set = try setArray.map { try decodeWeb3IdAttribute(from: $0) }
        
        let statement = AttributeNotInSetIdentityStatementV1(
            attributeTag: attributeTag,
            set: set
        )
        
        return .attributeNotInSet(statement: statement)
    }
    
    private static func decodeAttributeTag(from string: String) throws -> AttributeTag {
        // Use the existing AttributeTag initializer from Concordium SDK
        // AttributeTag has init?(_ description: String) that handles the parsing
        guard let attributeTag = AttributeTag(string) else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        return attributeTag
    }
    
    private static func decodeWeb3IdAttribute(from value: Any?) throws -> Web3IdAttribute {
        // Web3IdAttribute is an enum that can be string, numeric (UInt64), or timestamp (Date)
        guard let value = value else {
            throw SessionRequstError.unSupportedRequestMethod
        }
        
        // Handle string values
        if let stringValue = value as? String {
            return .string(value: stringValue)
        }
        
        // Handle number values (can be Int, Double, or NSNumber) - convert to UInt64
        if let intValue = value as? Int, intValue >= 0 {
            return .numeric(value: UInt64(intValue))
        } else if let uintValue = value as? UInt64 {
            return .numeric(value: uintValue)
        } else if let numberValue = value as? NSNumber {
            let uint64Value = numberValue.uint64Value
            return .numeric(value: uint64Value)
        }
        
        // Handle date-time objects - convert ISO8601 string to Date
        if let dateTimeDict = value as? [String: Any],
           let typeString = dateTimeDict["type"] as? String,
           typeString == "date-time",
           let timestampString = dateTimeDict["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = formatter.date(from: timestampString) else {
                throw SessionRequstError.unSupportedRequestMethod
            }
            return .timestamp(value: date)
        }
        
        throw SessionRequstError.unSupportedRequestMethod
    }
}

// Helper extension for Data hex decoding
extension Data {
    init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

