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
    func fetchTokens(contractIndex: String, contractSubindex: String) async throws -> CIS2TokenInfoBox
}

class CIS2Service: CIS2ServiceProtocol {
    let networkManager: NetworkManagerProtocol
    let storageManager: StorageManagerProtocol
    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) {
        self.networkManager = networkManager
        self.storageManager = storageManager
    }
    
    func fetchTokens(contractIndex: String, contractSubindex: String = "0") async throws -> CIS2TokenInfoBox {
        try await networkManager.load(
            ResourceRequest(
                url: ApiConstants.CIS2Token.tokens
                    .appendingPathComponent(contractIndex)
                    .appendingPathComponent(contractSubindex),
                parameters: ["limit" : "1000"]
            )
        )
    }
}
