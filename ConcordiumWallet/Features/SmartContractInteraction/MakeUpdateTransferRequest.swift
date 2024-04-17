//
//  MakeUpdateTransferRequest.swift
//  Mock
//
//  Created by Maksym Rachytskyy on 11.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

/// https://github.com/Concordium/concordium-base/tree/main/rust-bins/wallet-notes#create_account_transaction
/// https://github.com/Concordium/concordium-base/blob/main/rust-bins/wallet-notes/files/2-create_account_transaction-input.json
///
struct ContractUpdateRequestPayload: Codable {
    let amount: String
    let address: ContractAddress1
    let receiveName: String
    let message: String
    let maxContractExecutionEnergy: Int
}

enum UpdateTxType: String, Codable {
    case Update, Transfer, InitContract
}

// MARK: - MakeUpdateTransferRequest
struct MakeUpdateTransferRequest: Codable {
    let from: String
    let expiry: Int
    let nonce: Int
    let keys: AccountKeys
    let type: UpdateTxType
    let payload: ContractUpdateRequestPayload
    
    enum CodingKeys: String, CodingKey {
        case from = "from"
        case expiry = "expiry"
        case nonce = "nonce"
        case keys = "keys"
        case type = "type"
        case payload = "payload"
    }
    
    init(
        from: String,
        expiry: Int,
        nonce: Int,
        keys: AccountKeys,
        payload: ContractUpdateRequestPayload,
        type: UpdateTxType = .Update
    ) {
        self.from = from
        self.expiry = expiry
        self.nonce = nonce
        self.keys = keys
        self.type = type
        self.payload = payload
    }
}

// MARK: MakeUpdateTransferRequest convenience initializers and mutators

extension MakeUpdateTransferRequest {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MakeUpdateTransferRequest.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
