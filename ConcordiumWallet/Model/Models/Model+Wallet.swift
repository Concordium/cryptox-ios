//
//  Model+Wallet.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 01.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

extension Model.NFT {
    
    struct Wallet: Codable {
        let url: String
        var name: String?
        var count: Int
    }
}



extension Model.NFT.Wallet: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: Model.NFT.Wallet, rhs: Model.NFT.Wallet) -> Bool {
        return lhs.url == rhs.url
    }
}
