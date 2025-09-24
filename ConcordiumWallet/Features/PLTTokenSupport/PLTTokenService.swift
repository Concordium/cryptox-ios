//
//  PLTTokenService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import CryptoKit

protocol PLTTokenServiceProtocol {
    func fetchTokenInfoWithMetadata(for tokens: [String]) async -> [PLTTokenModel]
}

struct PLTTokenModel: Equatable, Hashable {
    let pltToken: PLTToken
    let metadata: PLTMetadata?
}

class PLTTokenService: PLTTokenServiceProtocol {
    let networkManager: NetworkManagerProtocol = ServicesProvider.defaultProvider().networkManager()
    let storageManager: StorageManagerProtocol = ServicesProvider.defaultProvider().storageManager()
    let session: URLSession

    
    init() {
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
    private func fetchTokens(limit: Int = 100) async throws -> [PLTToken] {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.PLTToken.tokens,
                parameters: ["limit" : "\(limit)"]
            )
        )
    }
    
    private func fetchTokens(for tokenID: String) async throws -> [PLTToken] {
        let allTokens = try await fetchTokens()
        return allTokens.filter{ $0.tokenID.lowercased().contains(tokenID.lowercased()) }
    }
    
    private func fetchTokenInfo(tokenID: String) async throws -> PLTToken {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.PLTToken.tokenInfo
                    .appendingPathComponent(tokenID)
            )
        )
    }
    
    private func fetchTokenInfo(for tokens: [String]) async -> [PLTToken] {
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
    
    func fetchTokenInfoWithMetadata(for tokens: [String]) async -> [PLTTokenModel] {
        await withTaskGroup(of: PLTTokenModel?.self, returning: [PLTTokenModel].self) { group in
            for tokenID in tokens {
                group.addTask { [weak self] () -> PLTTokenModel? in
                    guard let self else { return nil }
                    do {
                        let token = try await self.fetchTokenInfo(tokenID: tokenID)

                        // Verify TokenMetadata (keep or drop it)
                        let verifiedTM = await self.verifyTokenMetadata(token.tokenState.moduleState.metadata)

                        // Use verified metadata in the token we return
                        let tokenWithVerified = PLTToken(
                            tokenID: token.tokenID,
                            tokenState: TokenState(
                                decimals: token.tokenState.decimals,
                                moduleState: ModuleState(
                                    allowList: token.tokenState.moduleState.allowList,
                                    burnable:  token.tokenState.moduleState.burnable,
                                    denyList:  token.tokenState.moduleState.denyList,
                                    governanceAccount: token.tokenState.moduleState.governanceAccount,
                                    metadata: verifiedTM, // ← only if checksum OK
                                    mintable:  token.tokenState.moduleState.mintable,
                                    name:      token.tokenState.moduleState.name,
                                    paused:    token.tokenState.moduleState.paused
                                ),
                                tokenModuleRef: token.tokenState.tokenModuleRef,
                                totalSupply:    token.tokenState.totalSupply
                            )
                        )

                        let metadataURL = verifiedTM?.url
                        let pltMetadata: PLTMetadata?
                        if let metadataURL, let url = URL(string: metadataURL) {
                            do {
                                pltMetadata = try await self.fetchPLTMetadata(from: url)
                            } catch {
                                pltMetadata = nil
                            }
                        } else {
                            pltMetadata = nil
                        }

                        return PLTTokenModel(pltToken: tokenWithVerified, metadata: pltMetadata)
                    } catch {
                        return nil
                    }
                }
            }

            var out: [PLTTokenModel] = []
            for await item in group { if let item { out.append(item) } }
            return out
        }
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
    
    func fetchPLTMetadata(from url: URL) async throws -> PLTMetadata {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PLTMetadata.self, from: data)
    }
    
    func verifyTokenMetadata(_ tokenMetadata: TokenMetadata?) async -> TokenMetadata? {
        guard
            let tokenMetadata,
            let url = URL(string: tokenMetadata.url),
            let expectedChecksum = tokenMetadata.checksumSha256
        else {
            return tokenMetadata // no checksum to verify → keep as-is
        }

        do {
            let (data, _) = try await session.data(from: url)

            let hash = SHA256.hash(data: data)
            let actualChecksum = hash.map { String(format: "%02x", $0) }.joined()

            if actualChecksum.localizedCaseInsensitiveCompare(expectedChecksum) == .orderedSame {
                return tokenMetadata
            } else {
                print("⚠️ TokenMetadata checksum mismatch at \(url)")
                return nil
            }
        } catch {
            print("⚠️ Failed to fetch metadata for checksum verification: \(error)")
            return nil
        }
    }
}
