//
//  CIS2Service.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 09.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import CryptoKit

protocol CIS2ServiceProtocol {
    func fetchTokens(contractIndex: String, contractSubindex: String, limit: Int) async throws -> CIS2TokenInfoBox
    func fetchTokensMetadata(contractIndex: String, contractSubindex: String, tokenId: String) async throws -> CIS2TokensMetadata
}

class CIS2Service: CIS2ServiceProtocol {
    let networkManager: NetworkManagerProtocol
    let storageManager: StorageManagerProtocol
    let session: URLSession

    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.session = URLSession(configuration: URLSessionConfiguration.ephemeral)
    }
}

///
/// User case for token search by cintract index
///
///

enum ChecksumError: Error {
    case invalidChecksum
    case incorrectChecksum
}

extension CIS2Service {
    
    /// Fetches tokens from the contract based on the provided contract index and subindex.
    ///
    /// - Parameters:
    ///   - contractIndex: The index of the contract.
    ///   - contractSubindex: The subindex of the contract, default is "0".
    ///   - limit: The maximum number of tokens to fetch, default is 100.
    /// - Returns: A `CIS2TokenInfoBox` containing information about the tokens.
    func fetchTokens(contractIndex: String, contractSubindex: String = "0", limit: Int = 100) async throws -> CIS2TokenInfoBox {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.tokens
                    .appendingPathComponent(contractIndex)
                    .appendingPathComponent(contractSubindex),
                parameters: ["limit" : "\(limit)"]
            )
        )
    }
    
    /// Fetches all tokens data for a given contract.
    ///
    /// - Parameters:
    ///   - contractIndex: The index of the contract.
    ///   - tokenIds: An optional string of comma-separated token identifiers.
    /// - Returns: An array of `CIS2Token` objects containing the fetched tokens.
    func fetchAllTokensData(contractIndex: Int, tokenIds: String? = nil) async throws -> [CIS2Token] {
        let tokenIdsString: String
        if let tokenIds {
            tokenIdsString = tokenIds
        } else {
            let tokens = try await fetchTokens(contractIndex: String(contractIndex))
            tokenIdsString = tokens.tokens.map(\.token).joined(separator: ",")
        }
        
        let metadata = try await fetchTokensMetadata(contractIndex: String(contractIndex), tokenId: tokenIdsString)
        let tokenMetadataPairs = try await getTokenMetadataPair(metadata: metadata)
        
        return tokenMetadataPairs.map { item, tokenMetadata in
            CIS2Token(
                tokenId: item.tokenId,
                metadata: tokenMetadata,
                contractAddress: SmartContractAddress(index: contractIndex, subindex: 0),
                contractName: metadata.contractName
            )
        }
    }
    
    /// Fetches the balance of tokens for a specific account and token ID.
    ///
    /// - Parameters:
    ///   - contractIndex: The index of the contract.
    ///   - contractSubindex: The subindex of the contract, default is "0".
    ///   - accountAddress: The address of the account.
    ///   - tokenId: The ID of the token.
    /// - Returns: An array of `CIS2TokenBalance` objects.
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
    ///   - contractIndex: The index of the contract.
    ///   - contractSubindex: The subindex of the contract. Defaults to "0" if not provided.
    ///   - tokenId: A string of comma-separated identifiers representing the tokens for which metadata is to be fetched.
    /// - Returns: A `CIS2TokensMetadata` object containing the metadata of the specified tokens.
    func fetchTokensMetadata(contractIndex: String, contractSubindex: String = "0", tokenId: String) async throws -> CIS2TokensMetadata {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.cis2TokensMetadataV1
                    .appendingPathComponent(contractIndex)
                    .appendingPathComponent(contractSubindex),
                parameters: ["tokenId": tokenId]
            )
        )
    }
    
    func getCIS2TokenMetadata(url: URL, metadataChecksum: String?) async throws -> CIS2TokenMetadata {
        let (data, _) = try await session.data(from: url)
        
        if let metadataChecksum {
            try await verifyChecksum(checksum: metadataChecksum, responseData: data)
        }
        
        return try JSONDecoder().decode(CIS2TokenMetadata.self, from: data)
    }
    
    /// Verifies the checksum of the response data against a provided checksum.
    ///
    /// - Parameters:
    ///   - checksum: The expected checksum.
    ///   - responseData: The data to verify.
    /// - Throws: `ChecksumError.incorrectChecksum` if the checksums do not match.
    func verifyChecksum(checksum: String, responseData: Data) async throws {
        let hash = SHA256.hash(data: responseData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        guard hashString.localizedCaseInsensitiveCompare(checksum) == .orderedSame else {
            throw ChecksumError.incorrectChecksum
        }
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
                        guard let result = try? await self.getCIS2TokenMetadata(url: url, metadataChecksum: metadata.metadataChecksum) else {
                            return nil
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
