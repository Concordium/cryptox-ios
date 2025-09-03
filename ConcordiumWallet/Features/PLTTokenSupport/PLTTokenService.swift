//
//  PLTTokenService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

protocol PLTTokenServiceProtocol {
    func fetchTokens(limit: Int) async throws -> [PLTToken]
    func fetchTokenInfo(tokenID: String) async throws -> PLTToken
    func fetchTokens(for tokenID: String) async throws -> [PLTToken]
    func fetchTokenInfo(for tokens: [String]) async -> [PLTToken]
}

class PLTTokenService: PLTTokenServiceProtocol {
    let networkManager: NetworkManagerProtocol
    let storageManager: StorageManagerProtocol
    let session: URLSession

    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    }
}

extension PLTTokenService {
    
    /// Fetches tokens based on the provided tokenID.
    ///
    /// - Parameters:
    ///   - tokenId: The ID of the PLT token.
    ///   - limit: The maximum number of tokens to fetch, default is 100.
    /// - Returns: A `PLTToken` containing information about the tokens.
    func fetchTokens(limit: Int = 100) async throws -> [PLTToken] {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.PLTToken.tokens,
                parameters: ["limit" : "\(limit)"]
            )
        )
    }
    
    func fetchTokens(for tokenID: String) async throws -> [PLTToken] {
        let allTokens = try await fetchTokens()
        return allTokens.filter{ $0.tokenID.lowercased().contains(tokenID.lowercased()) }
    }
    
    func fetchTokenInfo(tokenID: String) async throws -> PLTToken {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.PLTToken.tokenInfo
                    .appendingPathComponent(tokenID)
            )
        )
    }
    
    func fetchTokenInfo(for tokens: [String]) async -> [PLTToken] {
        var results = [PLTToken]()

        await withTaskGroup(of: PLTToken?.self) { group in
            for token in tokens {
                group.addTask {
                    do {
                        return try await self.fetchTokenInfo(tokenID: token)
                    } catch {
                        print("❌ Failed to fetch token \(token): \(error)")
                        return nil
                    }
                }
            }

            for await result in group {
                if let token = result {
                    results.append(token)
                }
            }
        }

        return results
    }
    
    func fetchTokenBalances(for accountAddress: String) async throws -> [String: TokenAccountState] {
        let totalAccountBalance: AccountBalance = try await networkManager.load(ResourceRequest(url: ApiConstants.accountBalance.appendingPathComponent(accountAddress)))
        let pltTokenBalance: [String: TokenAccountState] = totalAccountBalance.balance?.accountTokens?.reduce(into: [:]) { result, token in
            let state = token.tokenAccountState
            let key = token.token.tokenID
            result[key] = state
        } ?? [:]
        return pltTokenBalance
    }
    
    func fetchTokenTotalSupply(for tokenId: String) async -> TokenBalance? {
        do {
            let token = try await self.fetchTokenInfo(tokenID: tokenId)
            return token.tokenState.totalSupply
        } catch { }
        return nil
    }
}
