//
//  SessionRequestType.swift
//  CryptoX
//
//  Created by Max on 15.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//


import Foundation
import ReownWalletKit

struct SessionRequestType: Codable {
    let type: TransferType
    
    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let typeStr = try container.decode(String.self, forKey: .type)
        if typeStr == "Update" {
            // For backwards compatibility with older versions of @concordium/wallet-connectors.
            type = TransferType.transferUpdate
        } else if typeStr == "transfer" {
            type = TransferType.simpleTransfer
        } else if typeStr == "tokenUpdate" {
            type = TransferType.tokenUpdate
        } else if let t = TransferType(rawValue: typeStr) {
            type = t
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid transaction type '\(typeStr)'")
        }
    }
}
