//
//  VerifiablePresentationRequestParams.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct IdQualifier: Codable {
    let type: String
    let issuers: [Int]
}

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
