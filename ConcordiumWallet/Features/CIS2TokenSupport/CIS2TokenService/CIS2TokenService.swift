//
//  InportTokenSerice.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 26.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

public struct SmartContractAddress: Codable, Equatable {
    public let index: Int
    public let subindex: Int
}

extension CIS2Token: Identifiable {
    var id: Int { tokenId.hashValue ^ metadata.decimals.hashValue ^ contractName.hashValue }
}

struct CIS2Token: Codable, Equatable {
    public let tokenId: String
    public let metadata: CIS2TokenMetadata
    public let contractAddress: SmartContractAddress
    public let contractName: String
    
    public init(tokenId: String, metadata: CIS2TokenMetadata, contractAddress: SmartContractAddress, contractName: String) {
        self.tokenId = tokenId
        self.metadata = metadata
        self.contractAddress = contractAddress
        self.contractName = contractName
    }
    
    public init(entity: CIS2TokenEntity) {
        self.tokenId = entity.tokenId
        self.contractName = entity.contractName
        self.metadata = CIS2TokenMetadata(
            name: entity.name,
            symbol: entity.symbol,
            decimals: entity.decimals,
            description: entity.descr,
            thumbnail: CIS2TokenMetadata.Thumbnail(url: entity.thumbnail),
            display: CIS2TokenMetadata.Thumbnail(url: entity.display),
            unique: false
        )
        self.contractAddress = .init(
            index: entity.index,
            subindex: entity.subindex
        )
    }
}

struct CIS2TokenInfo: Codable {
    let id: Int
    let token: String
    let totalSupply: String
    
    var isNotZero: Bool { totalSupply != "0" }
}

struct CIS2TokenInfoBox: Codable {
    let tokens: [CIS2TokenInfo]
}

struct CIS2TokensMetadataItem: Codable {
    let metadataChecksum: String?
    let metadataURL: String
    let tokenId: String
}

struct CIS2TokensMetadata: Codable {
    let contractName: String
    let metadata: [CIS2TokensMetadataItem]
}

extension CIS2TokenMetadata: Equatable {
    static func == (lhs: CIS2TokenMetadata, rhs: CIS2TokenMetadata) -> Bool {
        lhs.name == rhs.name
        && lhs.symbol == rhs.symbol
        && lhs.decimals == rhs.decimals
        && lhs.description == rhs.description
        && (lhs.unique ?? false) == (rhs.unique ?? false)
    }
}

struct CIS2TokenMetadata: Codable {
    struct Thumbnail: Codable, Equatable {
        enum ImageExtentionType {
            case svg, jpg, png
        }
        
        let url: String
        
        var type: ImageExtentionType {
            if url.contains(".jpg") {
                return .jpg
            } else if url.contains(".svg") {
                return .svg
            }
            
            return .png
        }
    }
    
    var name: String?
    var symbol: String? = ""
    var decimals: Int? = 0
    var description: String?
    var thumbnail: Thumbnail?
    var display: Thumbnail?
    var unique: Bool? = false
        
    internal init(
        name: String = "",
        symbol: String = "",
        decimals: Int = 0,
        description: String = "",
        thumbnail: CIS2TokenMetadata.Thumbnail? = nil,
        display: CIS2TokenMetadata.Thumbnail? = nil,
        unique: Bool = false
    ) {
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.description = description
        self.thumbnail = thumbnail
        self.display = display
        self.unique = unique
    }
}

struct CIS2TokenService {
    static var session: URLSession {
        return URLSession(configuration: URLSessionConfiguration.ephemeral)
    }
    
    
    // fetch all CIS2Tokens by index
    static func getCIS2Tokens(for index: Int) async throws -> [CIS2Token] {
        let tokens = try await CIS2TokenService.getCIS2Tokens(index: index)
        let containerBox = try await CIS2TokenService.getCIS2TokenMetadataContainer(index: index, tokenIds: tokens.map(\.token))
        
        return try await withThrowingTaskGroup(of: (CIS2TokenMetadata, CIS2TokensMetadataItem, String).self, body: { group in
            for c in containerBox.metadata {
                group.addTask {
                    try await (CIS2TokenService.getCIS2TokenMetadata(url: c.metadataURL), c, containerBox.contractName)
                }
            }
            
            var result = [CIS2Token]()
            for try await (meta, cont, contractName) in group {
                let t: CIS2Token = CIS2Token(
                    tokenId: cont.tokenId,
                    metadata: meta,
                    contractAddress: SmartContractAddress(index: index, subindex: 0),
                    contractName: contractName)
                result.append(t)
            }

            return result
        })
    }
    
    // fetch all Tokens metadata by index
    static func getTokensMetadata(for index: Int) async throws -> [CIS2TokenMetadata] {
        let tokens = try await CIS2TokenService.getCIS2Tokens(index: index)
        let container = try await CIS2TokenService.getCIS2TokenMetadataContainer(index: index, tokenIds: tokens.map(\.token)).metadata
        
        return try await withThrowingTaskGroup(of: CIS2TokenMetadata.self, body: { group in
            for metadataURL in container.map(\.metadataURL) {
                group.addTask {
                    try await CIS2TokenService.getCIS2TokenMetadata(url: metadataURL)
                }
            }
            
            var result = [CIS2TokenMetadata]()
            for try await meta in group {
                result.append(meta)
            }

            return result
        })
    }
    
    
    /// `GET /v0/CIS2Tokens/{index}/{subindex}`: get the list of tokens on a given contract address.
    static func getCIS2Tokens(index: Int) async throws -> [CIS2TokenInfo] {
        guard
            let request = ResourceRequest(url: ApiConstants.CIS2Token.tokens.appendingPathComponent("\(index)/0"), httpMethod: .get, body: nil).request,
            let url = request.url
        else {
            throw NetworkError.invalidResponse
        }
        logger.debugLog("[CIS2Token] getCIS2Tokens request: \(request)")
        let (data, _) = try await session.data(from: url)
        logger.debugLog("[CIS2Token] getCIS2Tokens response: \(String(data: data, encoding: .utf8))")
        
        return try JSONDecoder().decode(CIS2TokenInfoBox.self, from: data).tokens.filter(\.isNotZero)
    }
    
    /// `GET /v0/CIS2Tokens/{index}/{subindex}`: get the list of tokens on a given contract address.
    static func getCIS2TokenMetadataContainer(index: Int, tokenIds: [String]) async throws -> CIS2TokensMetadata {
        guard
            let request = ResourceRequest(
                url: ApiConstants.CIS2Token.tokenMetadata.appendingPathComponent("\(index)/0"),
                httpMethod: .get,
                parameters: ["tokenId": tokenIds.joined(separator: ",")],
                body: nil
            ).request,
            let url = request.url
        else {
            throw NetworkError.invalidResponse
        }
        logger.debugLog("[CIS2Token] getCIS2TokenMetadataContainer request: \(request)")
        let (data, _) = try await session.data(from: url)
        logger.debugLog("[CIS2Token] getCIS2TokenMetadataContainer response: \(String(data: data, encoding: .utf8))")
        return try JSONDecoder().decode(CIS2TokensMetadata.self, from: data)
    }
    
    /// `GET /v0/CIS2Tokens/{index}/{subindex}`: get the list of tokens on a given contract address.
    static func getCIS2TokenMetadata(url: String) async throws -> CIS2TokenMetadata {
        guard let url = URL(string: url) else { throw NetworkError.invalidResponse }
        let (data, _) = try await session.data(from: url)
        logger.debugLog("[CIS2Token] getCIS2TokenMetadata request: \(url.absoluteString)")
        logger.debugLog("[CIS2Token] getCIS2TokenMetadata response: \(String(data: data, encoding: .utf8))")
        return try JSONDecoder().decode(CIS2TokenMetadata.self, from: data)
    }
    
    /// `GET /v0/CIS2TokenBalance/{index}/{subindex}/{account address}`: get the balance of tokens on given contract address for a given account address.
    static func getCIS2TokenBalance(index: Int, tokenIds: [String], address: String) async throws -> [CIS2TokenBalance] {
        guard
            let request = ResourceRequest(
                url: ApiConstants.CIS2Token.tokensBalance.appendingPathComponent("\(index)/0/\(address)"),
                httpMethod: .get,
                parameters: ["tokenId": tokenIds.joined(separator: ",")],
                body: nil
            ).request,
            let url = request.url
        else {
            throw NetworkError.invalidResponse
        }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([CIS2TokenBalance].self, from: data)
    }
}

struct CIS2TokenBalance: Codable {
    let balance: String
    let tokenId: String
}
