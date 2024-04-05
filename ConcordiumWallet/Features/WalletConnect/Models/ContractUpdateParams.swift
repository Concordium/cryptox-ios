//
//  WCRequestTransaction.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct WCSignMessageTransaction: Codable {
    let message: String
}

struct ContractUpdateParams: Codable {
    let type: TransferType
    let sender: String
    let payload: ContractUpdatePayload
    
    enum CodingKeys: String, CodingKey {
        case type, sender, payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode 'type' field into TransferType.
        let typeStr = try container.decode(String.self, forKey: .type)
        if typeStr == "Update" {
            // For backwards compatibility with older versions of @concordium/wallet-connectors.
            type = TransferType.transferUpdate
        } else if let t = TransferType(rawValue: typeStr) {
            type = t
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid transaction type '\(typeStr)'")
        }
        
        // Decode sender and payload.
        sender = try container.decode(String.self, forKey: .sender)
        let payloadString = try container.decode(String.self, forKey: .payload)
        payload = try JSONDecoder().decode(ContractUpdatePayload.self, from: payloadString.data(using: .utf8) ?? Data())
    }
}
