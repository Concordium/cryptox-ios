//
//  CIS2Service.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 09.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

///
/// [WIP] Tihis service will be replacement for `CIS2TokenService`
///

protocol CIS2ServiceProtocol {
    func fetchTokens(contractIndex: String, contractSubindex: String, limit: Int) async throws -> CIS2TokenInfoBox
    func fetchTokensMetadata(contractIndex: String, contractSubindex: String, tokenId: String) async throws -> CIS2TokensMetadata
}

class CIS2Service: CIS2ServiceProtocol {
    let networkManager: NetworkManagerProtocol
    let storageManager: StorageManagerProtocol
    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) {
        self.networkManager = networkManager
        self.storageManager = storageManager
    }
}

///
/// User case for token search by cintract index
///
extension CIS2Service {
    func fetchTokens(contractIndex: String, contractSubindex: String = "0", limit: Int = 1000) async throws -> CIS2TokenInfoBox {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.tokens
                    .appendingPathComponent(contractIndex)
                    .appendingPathComponent(contractSubindex),
                parameters: ["limit" : "\(limit)"]
            )
        )
    }
    
    func fetchTokensBalance(contractIndex: String, contractSubindex: String = "0", accountAddress: String, tokenId: String) async throws -> [CIS2TokenBalance] {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.cis2TokenBalanceV1
                    .appendingPathComponent(contractIndex)
                    .appendingPathComponent(contractSubindex)
                    .appendingPathComponent(accountAddress),
                parameters: ["tokenId": tokenId]
            )
        )
    }

    /// Fetches metadata for tokens specified by their identifiers within a contract.
    ///
    /// - Parameters:
    ///   - contractIndex: The index of the contract to fetch token metadata from.
    ///   - contractSubindex: The subindex of the contract. Defaults to "0" if not provided.
    ///   - tokenIds: An string of comma separated string identifiers representing the tokens for which metadata is to be fetched.
    ///   - API: `GET /v1/CIS2Tokens/{index}/{subindex}`
    ///
    func fetchTokensMetadata(contractIndex: String, contractSubindex: String = "0", tokenId: String) async throws -> CIS2TokensMetadata {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.cis2TokensMetadataV1.appendingPathComponent(contractIndex).appendingPathComponent(contractSubindex),
                parameters: ["tokenId" : tokenId]
            )
        )
    }
    
    func getCIS2TokenMetadata(url: URL) async throws -> CIS2TokenMetadata {
        try await networkManager.load(ResourceRequest(url: url))
    }
}

extension CIS2Service {
    /// Retrieves a pair of metadata items and their corresponding token metadata details.
    ///
    /// This function asynchronously retrieves pairs of metadata items and their corresponding token metadata details from the provided `CIS2TokensMetadata`.
    /// It utilizes the `getCIS2TokenMetadata` method of the `service` object to fetch token metadata details for each metadata item's URL.
    ///  If a metadata item's URL is invalid or fetching the details fails, the entire item will be skipped in the result.
    ///
    /// - Parameter metadata: The `CIS2TokensMetadata` containing the metadata items.
    ///
    /// - Returns: An array of tuples, each containing a `CIS2TokensMetadataItem` and its corresponding `CIS2TokenMetadataDetails`.
    ///
    func getTokenMetadataPair(metadata: CIS2TokensMetadata) async throws -> [(CIS2TokensMetadataItem, CIS2TokenMetadata)] {
        try await withThrowingTaskGroup(of: (CIS2TokensMetadataItem, CIS2TokenMetadata)?.self) { [weak self] group in
            guard let self else { return [] }
            for metadata in metadata.metadata {
                if let url = URL(string: metadata.metadataURL) {
                    group.addTask {
                        guard let result = try? await self.getCIS2TokenMetadata(url: url) else {
                            return nil
                        }
                        
                        if let metadataChecksum = metadata.metadataChecksum {
                            //TODO: - add verification checksum here
                            // result.hash check
                        }
                        
                        return (metadata, result)
                    }
                }
            }
            
            return try await group
                .compactMap { $0 }
                .reduce(into: []) { $0.append($1) }
        }
    }
}
