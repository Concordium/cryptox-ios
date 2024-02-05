//
//  Model+Marketplace.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 01.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


extension Model.NFT {
    
    struct Marketplace: Codable {
        let url: String
        var name: String?
    }
}



extension Model.NFT.Marketplace: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: Model.NFT.Marketplace, rhs: Model.NFT.Marketplace) -> Bool {
        return lhs.url == rhs.url
    }
}
