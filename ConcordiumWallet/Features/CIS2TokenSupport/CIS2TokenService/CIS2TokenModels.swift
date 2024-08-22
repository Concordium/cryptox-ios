//
//  CIS2TokenModels.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 26.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

public struct SmartContractAddress: Codable, Equatable, Hashable {
    public let index: Int
    public let subindex: Int
}

extension CIS2Token: Identifiable {
    var id: Int { tokenId.hashValue ^ metadata.decimals.hashValue ^ contractName.hashValue }
}

struct CIS2Token: Codable {
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

extension CIS2Token: Equatable {
    static func == (lhs: CIS2Token, rhs: CIS2Token) -> Bool {
        lhs.id == rhs.id
    }
}

extension CIS2Token: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tokenId)
        hasher.combine(contractName)
        hasher.combine(contractAddress)
        hasher.combine(metadata)
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

struct CIS2TokensMetadataItem: Codable, Hashable {
    let metadataChecksum: String?
    let metadataURL: String
    let tokenId: String
}

struct CIS2TokensMetadata: Codable, Hashable {
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
    struct Thumbnail: Codable, Equatable, Hashable {
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

extension CIS2TokenMetadata: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(symbol)
        hasher.combine(decimals)
        hasher.combine(description)
        hasher.combine(thumbnail)
        hasher.combine(display)
        hasher.combine(unique)
    }
}

struct CIS2TokenBalance: Codable {
    let balance: String
    let tokenId: String
}
