//
//  NFTService.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import Combine


class NFTService {
    private let mobileWallet: MobileWalletProtocol
    private var networkManager: NetworkManagerProtocol
    private var storageManager: StorageManagerProtocol
    
    private var cancellables = [AnyCancellable]()

    lazy var wallets: [ExportRecipient] = {
        return storageManager.getWallets()
    }()

    init(mobileWallet: MobileWalletProtocol, networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) {
        self.mobileWallet = mobileWallet
        self.networkManager = networkManager
        self.storageManager = storageManager
    }
    
    func fetchTokens(from domain: String, by wallets: [String]) async throws -> [Model.NFT.Token] {
        try await withThrowingTaskGroup(of: [Model.NFT.Token].self) { group in
            for address in wallets {
                group.addTask{
                    let items = try await NFTFetcher.fetch(from: domain, by: address)
                    return items
                }
            }
            
            var items: [Model.NFT.Token] = []
            
            for try await tokens in group {
                items.append(contentsOf: tokens)
            }

            return items
        }
    }
    
    
    
    func fetch(wallets: [ExportRecipient]) async throws -> [NFTMarketplaceViewModel] {
        try await withThrowingTaskGroup(of: NFTMarketplaceViewModel.self) { group in
            for marketplace in NFTRepository.MarketPlace.feth() {
                group.addTask{
                    return try await self.fetch(marketplace: marketplace, wallets: wallets)
                }
            }
            
            var items: [NFTMarketplaceViewModel] = []
            for try await item in group {
                items.append(item)
            }
            
            return items
        }
    }
    
    
    func fetch(marketplace: NFTRepository.MarketPlace, wallets: [ExportRecipient]) async throws -> NFTMarketplaceViewModel {
        try await withThrowingTaskGroup(of: NFTWalletViewModel.self) { group in
            for wallet in wallets {
                group.addTask{
                    return try await NFTFetcher.fetch(host: marketplace.host, name: marketplace.name, wallet: wallet)
                }
            }
            
            var items: [NFTWalletViewModel] = []
            for try await item in group {
                items.append(item)
            }
            
            return NFTMarketplaceViewModel(uuid: marketplace.uuid, url: marketplace.host, name: marketplace.name, wallets: items.filter({ $0.count != 0 }))
        }
    }
    
    
    func fetchAccounts() -> [String] {
        return wallets.map({ $0.address })
    }
    
}


//

struct NFTFetcher {

    static var session: URLSession {
        return URLSession(configuration: URLSessionConfiguration.ephemeral)
    }

    // add
    static func fetch(from domain: String, by address: String) async throws -> [Model.NFT.Token] {
        
        let parameters: [String: CustomStringConvertible] = [
            "blockchain_id": "2",
            "address": address,
            "page_start": 0,
            "page_limit": 6000,
            "search_string": ""
        ]
        
        guard let domain = URL(string: domain) else { throw NetworkError.invalidResponse }
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else { throw NetworkError.invalidResponse }
        guard let request = ResourceRequest(url: ApiConstants.build(domain: domain), httpMethod: .post, body: theJSONData).request else { throw NetworkError.invalidResponse }
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Model.NFT.Page.self, from: data).tokens
    }
    
    
    // fetch
    static func fetch(host: String, name: String, wallet: ExportRecipient) async throws -> NFTWalletViewModel {
        
        let emptyWallet = NFTWalletViewModel(address: wallet.address, name: wallet.name, tokens: [])
        
        let parameters: [String: CustomStringConvertible] = [
            "blockchain_id": "2",
            "address": wallet.address,
            "page_start": 0,
            "page_limit": 6000,
            "search_string": ""
        ]
        
        guard let url = URL(string: host) else { return emptyWallet }
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else { return emptyWallet}
        guard let request = ResourceRequest(url: ApiConstants.build(domain: url), httpMethod: .post, body: theJSONData).request else { return emptyWallet }
        let (data, _) = try await session.data(for: request)
        do {
            let tokens = try JSONDecoder().decode(Model.NFT.Page.self, from: data).tokens
            return NFTWalletViewModel(address: wallet.address, name: wallet.name, tokens: tokens)
        } catch _ {
            return emptyWallet
        }
    }
}
