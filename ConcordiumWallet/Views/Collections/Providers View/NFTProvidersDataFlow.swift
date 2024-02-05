//
//  NFTProvidersDataFlow.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

struct NFTMarketplaceViewModel: Codable {
    
    let uuid: UUID
    let url: String
    var name: String
    var wallets: [NFTWalletViewModel]
    
    var count:  Int {
        return wallets.reduce(0) { partialResult, item in
            partialResult + item.count
        }
    }
    
    init(uuid: UUID, url: String, name: String, wallets: [NFTWalletViewModel]) {
        self.uuid = uuid
        self.url = url
        self.name = name
        self.wallets = wallets
    }
}


struct NFTWalletViewModel: Codable {
    let address: String
    let name: String
    let tokens: [Model.NFT.Token]
    
    var count:  Int {
        return tokens.count
    }
    
    init(address: String, name: String, tokens:[Model.NFT.Token]) {
        self.address = address
        self.name 	= name
        self.tokens = tokens
    }
}


enum NFTProviders {
    
    enum Mode {
        case marketplace
        case wallet([NFTWalletViewModel], title: String)
        case tokens([Model.NFT.Token], title: String)
    }
    
    struct Section {
        // MARK: - Header
        enum Header {
            case header
            case noHeader
        }

        // MARK: - Model
        enum Item {
            case noItems
            case marketplace(NFTMarketplaceViewModel)
            case wallet(NFTWalletViewModel)
            case token(NFTTokenViewModel)
        }

        var header: Header
        var items: [Item]
    }
    
    
    
    // MARK: - State
    enum ViewControllerState {
        case loading
        case result([Section])
        case emptyResult
        case error
    }
    
    // MARK: - Action
    enum Action: ActionTypeProtocol {
        case openMarketplace(model: NFTMarketplaceViewModel)
        case openWallet(model: NFTWalletViewModel)
        case openToken(model: NFTTokenViewModel)
        case delete(model: NFTMarketplaceViewModel)
        case fetch(forceReload: Bool)
        case search(String)
    }
}



extension NFTProviders.Section {
    
    var isEmpty: Bool {
        return items.isEmpty
    }
}
