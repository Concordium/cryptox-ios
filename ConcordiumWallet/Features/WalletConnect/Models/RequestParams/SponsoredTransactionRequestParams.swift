//
//  SponsoredTransactionRequestParams.swift
//  CryptoX
//
//  Created on 2026.
//  Copyright © 2026 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

/// Parameters for a sponsored transaction request
struct SponsoredTransactionRequestParams: Codable {
    /// HEX-encoded transaction payload bytes (type byte + payload bytes)
    let payload: String
    
    /// Optional schema for contract update transactions (same as sign_and_send_transaction)
    let schema: ContractSchema?
    
    /// HEX-encoded TransactionHeaderV1 bytes
    let header: String
    
    /// HEX-encoded TransactionSignature (sponsor signature)
    let sponsorSignature: String
    
    enum CodingKeys: String, CodingKey {
        case payload
        case schema
        case header
        case sponsorSignature
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payload = try container.decode(String.self, forKey: .payload)
        schema = try container.decodeIfPresent(ContractSchema.self, forKey: .schema)
        header = try container.decode(String.self, forKey: .header)
        sponsorSignature = try container.decode(String.self, forKey: .sponsorSignature)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payload, forKey: .payload)
        // ContractSchema is only Decodable, not Encodable, so we skip encoding it
        // This is fine since this struct is primarily used for decoding WalletConnect requests
        try container.encode(header, forKey: .header)
        try container.encode(sponsorSignature, forKey: .sponsorSignature)
    }
}

