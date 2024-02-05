//
//  Model+Token.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 05.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


extension Model {
    
    enum NFT {
        
        struct ResponseMeta: Codable {
            struct Error: Codable {
                var messages: [String]
                var code: String
            }
            
            var status: String
            var error: Error?
            
            enum CodingKeys: String, CodingKey {
                case status = "status"
            }
        }
        
        struct Page: Codable {
            let responseMeta: ResponseMeta?
            let tokens: [Token]
            let pageLimit, totalItems: Int?
            
            enum CodingKeys: String, CodingKey {
                case responseMeta = "response_meta"
                case tokens
                case pageLimit = "page_limit"
                case totalItems = "total_items"
            }
        }
        
        // MARK: - Token
        struct Token: Codable {
            let blockchainID: String
            let nftID: String
            let marketplace: String
            let marketplaceName: String
            let nftPage: String
            let nftMetadataURL: String?
            let nftName, ownerAddress, authorAddress: String
            let authorRoyalty: String
            let iconPreviewURL: String?
            let imageURL: String?
            let quantity, totalMinted, saleStatus: String
            
            enum CodingKeys: String, CodingKey {
                case blockchainID = "blockchain_id"
                case nftID = "nft_id"
                case marketplace
                case marketplaceName = "marketplace_name"
                case nftPage = "nft_page"
                case nftMetadataURL = "nft_metadata_url"
                case nftName = "nft_name"
                case ownerAddress = "owner_address"
                case authorAddress = "author_address"
                case authorRoyalty = "author_royalty"
                case iconPreviewURL = "icon_preview_url"
                case imageURL = "image_url"
                case quantity
                case totalMinted = "total_minted"
                case saleStatus = "sale_status"
            }
        }
    }
}




extension Model.NFT.Token: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(nftID)
    }
    
    static func == (lhs: Model.NFT.Token, rhs: Model.NFT.Token) -> Bool {
        return lhs.nftID == rhs.nftID && lhs.marketplace == rhs.marketplace
    }
}
