//
//  WCRequestTransaction.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct WCRequestTransaction: Codable {
    struct Schema: Codable {
        let type: String
        let value: String
    }
    
    let sender: String
    let payload: UpdateTxPayload
    
    enum CodingKeys: String, CodingKey {
        case sender, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payloadString = try container.decode(String.self, forKey: .payload)
        
        sender = try container.decode(String.self, forKey: .sender)
        payload = try JSONDecoder().decode(UpdateTxPayload.self, from: payloadString.data(using: .utf8) ?? Data())
    }
}
