//
//  ImportTokenViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

@MainActor
final class ImportTokenViewModel: ObservableObject {
    @State var accountSavedCIS2Tokens: [CIS2Token]
    @Published var tokens: [CIS2Token] = []
    @Published var searchResultToken: CIS2Token?
    @Published var selectedToken: CIS2Token?
    @Published var error: ImportTokenError?
    @Published var isLoading: Bool = false
    @Published var hasMore: Bool = true
    @Published var currentPage = 1
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    private let storageManager: StorageManagerProtocol
    private let networkManager: NetworkManagerProtocol
    private let account: AccountDataType
    private var allContractTokens = [String]()
    private let batchSize = 20
    private var contractIndex: Int?
    
    private let cis2Service: CIS2Service
    
    init(storageManager: StorageManagerProtocol, networkManager: NetworkManagerProtocol, account: AccountDataType) {
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.account = account
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
        
        logger.debugLog("savedTokens: -- \(self.storageManager.getAccountSavedCIS2Tokens(account.address))")
        _accountSavedCIS2Tokens = State(initialValue: storageManager.getAccountSavedCIS2Tokens(account.address))
    }
    
    func search(name: String) async {
        do {
            guard let index = Int(name) else { return }
            allContractTokens = try await cis2Service.fetchTokens(contractIndex: name).tokens.map(\.token)
            contractIndex = index
            loadMore()
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
    
    func saveToken(_ token: CIS2Token?) {
        guard let token = token else { return }
        guard !storageManager.getAccountSavedCIS2Tokens(account.address).contains(token) else { return }
        
        do {
            try storageManager.storeCIS2Token(token: token, address: account.address)
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
    
    func loadMore() {
        guard !isLoading, hasMore, let contractIndex else { return }
        
        isLoading = true
        
        Task {
            do {
                let ids = allContractTokens.dropFirst((currentPage - 1) * batchSize).prefix(batchSize)
                
                guard !ids.isEmpty else {
                    return await MainActor.run {
                        hasMore = false
                        isLoading = false
                    }
                }
                
                let fetchedTokens = try await self.cis2Service.fetchAllTokensData(contractIndex: contractIndex, tokenIds: ids.joined(separator: ","))
                
                await MainActor.run {
                    
                    if currentPage == 1 {
                        tokens = fetchedTokens
                    } else {
                        tokens += fetchedTokens
                    }
                    hasMore = tokens.count < allContractTokens.count
                    currentPage += 1
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    func initialSearchState() {
        loadInitial()
        allContractTokens.removeAll()
        tokens.removeAll()
    }
    
    func loadInitial() {
        hasMore = true
        isLoading = false
        currentPage = 1
        selectedToken = nil
        error = nil
    }
    
    func isTokenAlreadyImported(tokenId: String) -> Bool {
        return accountSavedCIS2Tokens.filter { $0.contractAddress.index == contractIndex }.contains { $0.tokenId == tokenId }
    }
}
