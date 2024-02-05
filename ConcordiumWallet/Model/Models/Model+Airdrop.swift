//
//  Model+Airdrop.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 04.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


// MARK: – Airdrop
extension Model {
    
    struct Airdrop: Codable {
        
        struct Meta: Codable {
            let status: String
        }
        
        let responseMeta: Meta
        let success: Bool
        let message: String
    }
}


extension Model.Airdrop {
    
    private enum CodingKeys: String, CodingKey {
        case responseMeta = "response_meta"
        case success
        case message
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        responseMeta = try container.decode(Model.Airdrop.Meta.self, forKey: .responseMeta)
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try container.decode(String.self, forKey: .message)
    }
}


// MARK: – Flyer
extension Model {

    struct Flyer: Codable {
        let apiUrl: String
        let airdropId: String
        let airdropName: String
        let marketplaceName: String
        let marketplaceUrl: String
        let marketplaceIcon: String
    }
}


extension Model.Flyer {
    
    private enum CodingKeys: String, CodingKey {
        case apiUrl = "api_url"
        case airdropId = "airdrop_id"
        case airdropName = "airdrop_name"
        case marketplaceName = "marketplace_name"
        case marketplaceUrl = "marketplace_url"
        case marketplaceIcon = "marketplace_icon"
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        apiUrl = try container.decode(String.self, forKey: .apiUrl)
        airdropId = try container.decode(String.self, forKey: .airdropId)
        airdropName = try container.decode(String.self, forKey: .airdropName)
        marketplaceName = try container.decode(String.self, forKey: .marketplaceName)
        marketplaceUrl = try container.decode(String.self, forKey: .marketplaceUrl)
        marketplaceIcon = try container.decode(String.self, forKey: .marketplaceIcon)
    }
}
