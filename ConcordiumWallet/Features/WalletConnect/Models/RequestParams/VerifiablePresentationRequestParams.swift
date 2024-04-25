//
//  VerifiablePresentationRequestParams.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

//{\"type\":\"AttributeInRange\",\"attributeTag\":\"dob\",\"lower\":\"19590419\",\"upper\":\"20060418\"}

struct IdQualifier: Codable {
    let type: String
    let issuers: [Int]
}

//enum AttributeTag: String, Codable {
//    case dob, firstName, lastName, sex, countryOfResidence, nationality, idDocType, idDocNo, idDocIssuer, idDocIssuedAt, idDocExpiresAt, nationalIdNo, taxIdNo
//}

//extension AttributeTag {
//    var title: String {
//        switch self {
//            case .dob: return "Age"
//            case .firstName: return "First Name"
//            case .lastName: return "Last Name"
//            case .sex: return "Sex"
//            case .countryOfResidence: return "Country of residence"
//            case .nationality: return "Nationality"
//            case .idDocType: /*identity_attribute_doc_type*/
//                return "Identity document type"
//            case .idDocNo:
//                return "Identity document number"
//            case .idDocIssuer:
//                return "Identity document issuer"
//            case .idDocIssuedAt:
//                return "ID valid from"
//            case .idDocExpiresAt:
//                return "ID valid to"
//            case .nationalIdNo:
//                return "National ID number"
//            case .taxIdNo:
//                return "Tax ID number"
//        }
//    }
//}


/* `RevealAttribute`
 🐞 wc: --- sessionRequestPublisher (request: WalletConnectSign.Request(id: 1713514912077485, topic: "7e406c42a3b9c7ab350d0c2c8cbd678f322f4454c2d042e65abeb6199b02bf4a", method: "request_verifiable_presentation", params: AnyCodable: "{"paramsJson":"{
        \"challenge\":\"89d614bf0503806f633ed5e784a63edc20b784fe2edd681427b8b543c426ac33\",
        \"credentialStatements\":
        [{\"statement\":[{\"type\":\"RevealAttribute\",\"attributeTag\":\"taxIdNo\"}],\"idQualifier\":{\"type\":\"cred\",\"issuers\":[0]}}]}"}",
    chainId: ccd:testnet,
    expiry: nil), context: nil)
 
    `VerifiablePresentationStatement` -- {\"statement\":[{\"type\":\"RevealAttribute\",\"attributeTag\":\"taxIdNo\"}
 */

struct VerifiablePresentationStatement: Codable, Identifiable {
    enum StatementType: String, Codable {
        case revealAttribute = "RevealAttribute"
        case attributeInRange = "AttributeInRange"
        case attributeInSet = "AttributeInSet"
        case attributeNotInSet = "AttributeNotInSet"
    }
    
    var id: Int { type.hashValue ^ attributeTag.hashValue }
    
    let type: StatementType
    let attributeTag: ChosenAttributeKeys
    
    let lower: String?
    let upper: String?
    let set: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type, attributeTag, lower, upper, set
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(StatementType.self, forKey: .type)
        attributeTag = try container.decode(ChosenAttributeKeys.self, forKey: .attributeTag)
        lower = try container.decodeIfPresent(String.self, forKey: .lower)
        upper = try container.decodeIfPresent(String.self, forKey: .upper)
        set = try container.decodeIfPresent(Array<String>.self, forKey: .set)
    }
    
    var lowerAsDate: Date {
        guard let lower = lower else { return Date() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: lower) ?? Date()
    }
    
    var upperAsDate: Date {
        guard let upper = upper else { return Date() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: upper) ?? Date()
    }
}

extension VerifiablePresentationStatement.StatementType {
    var title: String {
        switch self {
            case .revealAttribute: return "Information to reveal"
            case .attributeInRange: return "Zero-knowledge proof"
            case .attributeInSet: return "Zero-knowledge proof"
            case .attributeNotInSet: return "Zero-knowledge proof"
        }
    }
}

struct VerifiablePresentationStatements: Codable, Identifiable {
    let id = UUID()

    let statement: [VerifiablePresentationStatement]
    let idQualifier: IdQualifier?
}

struct VerifiablePresentationRequestParams: Codable{
    let challenge: String
    let credentialStatements: [VerifiablePresentationStatements]
}
