//
//  CIS2TokenDetailView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

final class CIS2TokenDetailViewModel: ObservableObject {
    let sceneTitle: String
    let tokenName: String
    let thumbnail: URL?
    let display: URL?
    let contractAddress: String
    let ticker: String
    let tokenId: String
    let description: String?
    let decimals: String
    
    @Published var balance: String = "0.0"

    var tokenBalance: CIS2TokenBalance?
    let account: AccountDataType
    let token: CIS2Token
    
    private let storageManager: StorageManagerProtocol
    private let networkManager: NetworkManagerProtocol
    private let cis2Service: CIS2Service
    private let onDismiss: () -> Void
    
    init(
        _ token: CIS2Token,
        account: AccountDataType,
        storageManager: StorageManagerProtocol,
        networkManager: NetworkManagerProtocol,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.token = token
        self.account = account
        self.sceneTitle = token.metadata.name ?? ""
        self.balance = "0.0"
        self.thumbnail = token.metadata.thumbnail?.url.toURL
        self.display = token.metadata.display?.url.toURL
        self.tokenName = token.metadata.name ?? ""
        self.contractAddress = "\(token.contractAddress.index),\(token.contractAddress.subindex)"
        self.ticker = token.metadata.symbol ?? ""
        self.tokenId = token.tokenId
        self.description = token.metadata.description
        self.decimals = "\(token.metadata.decimals ?? 0)"
        
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
    }
    
    @MainActor
    func reload() async {
        do {
            let balances = try await cis2Service.fetchTokensBalance(contractIndex: token.contractAddress.index.string, accountAddress: account.address, tokenId: token.tokenId)
            if let b = balances.first {
                self.balance = TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: b.balance), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ",")
            }
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
    
    func removeToken() {
        do {
            try storageManager.removeCIS2Token(token: token, address: account.address)
            self.onDismiss()
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}
