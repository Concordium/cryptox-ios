//
//  ReownSessionRequest.swift
//  CryptoX
//
//  Created by Max on 13.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

// MARK: - ReownSessionRequest
struct ReownSessionRequest: Codable {
    let type: String
    let payload: String
    let schema: ReownSchema
    let sender: String

    enum CodingKeys: String, CodingKey {
        case type
        case payload
        case schema
        case sender
    }

    func decodedPayload() -> ReownPayload? {
        let decoder = JSONDecoder()
        if let payloadData = payload.data(using: .utf8) {
            do {
                return try decoder.decode(ReownPayload.self, from: payloadData)
            } catch {
                debugPrint("Error decoding payload: \(error)")
            }
        }
        return nil
    }
}

struct ReownPayload: Codable {
    let amount: String
    let address: ReownAddress
    let receiveName: String
    let maxContractExecutionEnergy: Int
    let message: String

    enum CodingKeys: String, CodingKey {
        case amount
        case address
        case receiveName
        case maxContractExecutionEnergy
        case message
    }
}

struct ReownAddress: Codable {
    let index: Int
    let subindex: Int

    enum CodingKeys: String, CodingKey {
        case index
        case subindex
    }
}

struct ReownSchema: Codable {
    let value: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case value
        case type
    }

    func decodedValue() -> String? {
        if let decodedData = Data(base64Encoded: value) {
            return String(data: decodedData, encoding: .utf8)
        }
        return nil
    }
}
