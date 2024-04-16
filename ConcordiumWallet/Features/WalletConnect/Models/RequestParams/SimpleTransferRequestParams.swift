//
//  SimpleTransferRequest.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 12.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct SimpleTransferRequestPayload: Codable {
    let amount: String
    let toAddress: String
}

struct SimpleTransferRequestParams: Codable {
    let type: TransferType
    let sender: String
    let payload: SimpleTransferRequestPayload
    
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
        } else if typeStr == "transfer" {
            type = TransferType.simpleTransfer
        } else if let t = TransferType(rawValue: typeStr) {
            type = t
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid transaction type '\(typeStr)'")
        }
        
        // Decode sender and payload.
        sender = try container.decode(String.self, forKey: .sender)
        
        let payloadString = try container.decode(String.self, forKey: .payload)
        payload = try JSONDecoder().decode(SimpleTransferRequestPayload.self, from: payloadString.data(using: .utf8) ?? Data())
    }
}

extension SimpleTransferRequestParams {
    func costParameters() -> [TransferCostParameter] {
        [
            .amount("\(payload.amount)"),
            .sender(sender),
            .receiveName(payload.toAddress)
        ]
    }
}
