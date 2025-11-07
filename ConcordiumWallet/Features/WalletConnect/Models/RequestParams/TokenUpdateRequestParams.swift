//
//  TokenUpdateRequestParams.swift
//  CryptoX
//
//  Created by Max on 15.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

struct TokenUpdateRequestPayload: Codable {
    let tokenId: String
    let operations: String // HEX-encoded CBOR-encoded array of operations
}

struct TokenUpdateRequestParams: Codable {
    let type: TransferType
    let sender: String
    let payload: TokenUpdateRequestPayload
    
    enum CodingKeys: String, CodingKey {
        case type, sender, payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode 'type' field into TransferType.
        let typeStr = try container.decode(String.self, forKey: .type)
        if typeStr == "tokenUpdate" {
            type = TransferType.tokenUpdate
        } else if let t = TransferType(rawValue: typeStr) {
            type = t
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid transaction type '\(typeStr)'")
        }
        
        // Decode sender and payload.
        sender = try container.decode(String.self, forKey: .sender)
        
        let payloadString = try container.decode(String.self, forKey: .payload)
        payload = try JSONDecoder().decode(TokenUpdateRequestPayload.self, from: payloadString.data(using: .utf8) ?? Data())
    }
}

extension TokenUpdateRequestParams {
    /// Parse operations from the hex-encoded CBOR string
    func parseOperations() throws -> [TokenUpdateOperation] {
        guard let operations = TokenUpdateOperation.parseOperationsFromHex(payload.operations) else {
            throw SessionRequstError.generic("Failed to parse operations from payload")
        }
        
        // For now, only support a single "transfer" operation
        guard operations.count == 1 else {
            throw SessionRequstError.generic("Only single transfer operation is supported")
        }
        
        guard case .transfer = operations[0] else {
            throw SessionRequstError.generic("Only transfer operation is supported")
        }
        
        return operations
    }
}

