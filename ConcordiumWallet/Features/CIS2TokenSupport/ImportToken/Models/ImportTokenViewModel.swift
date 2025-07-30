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
    @Published var tokens: UnifiedTokensResult = UnifiedTokensResult(cis2: [], plt: [])
    @Published var searchResultToken: CIS2Token?
    @Published var selectedToken: UnifiedToken?
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
    private let pltService: PLTTokenService
    private let tokenFetcher: TokenFetcher
    
    init(storageManager: StorageManagerProtocol, networkManager: NetworkManagerProtocol, account: AccountDataType) {
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.account = account
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
        self.pltService = PLTTokenService(networkManager: networkManager, storageManager: storageManager)
        self.tokenFetcher = TokenFetcher(pltTokenService: pltService, cis2Service: cis2Service)
        logger.debugLog("savedTokens: -- \(self.storageManager.getAccountSavedCIS2Tokens(account.address))")
        _accountSavedCIS2Tokens = State(initialValue: storageManager.getAccountSavedCIS2Tokens(account.address))
    }
    
    func search(name: String) async {
        // Reset state before new search
        initialSearchState()
        
        var newTokens = [String]()
        
        async let pltFetch: Result<[String], Error> = {
            do {
                let tokens = try await pltService.fetchTokens(for: name)
                return .success(tokens.map(\.tokenState.moduleState.name))
            } catch {
                return .failure(error)
            }
        }()

        async let cis2Fetch: Result<[String], Error> = {
            do {
                let tokens = try await cis2Service.fetchTokens(contractIndex: name).tokens
                return .success(tokens.map(\.token))
            } catch {
                return .failure(error)
            }
        }()

        let pltResult = await pltFetch
        let cis2Result = await cis2Fetch

        switch pltResult {
        case .success(let plt):
            newTokens.append(contentsOf: plt)
        case .failure(let err):
            logger.errorLog("PLT error: \(err.localizedDescription)")
        }

        switch cis2Result {
        case .success(let cis2):
            newTokens.append(contentsOf: cis2)
        case .failure(let err):
            logger.errorLog("CIS2 error: \(err.localizedDescription)")
        }

        if let tokenContractIndex = Int(name) {
            contractIndex = tokenContractIndex
        }

        allContractTokens = newTokens
        loadMore()
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
            let ids = Array(allContractTokens.dropFirst((currentPage - 1) * batchSize).prefix(batchSize))

            guard !ids.isEmpty else {
                return await MainActor.run {
                    hasMore = false
                    isLoading = false
                }
            }

            let fetchedTokens = await tokenFetcher.fetchAllTokens(for: ids, contractIndex: contractIndex)

            await MainActor.run {
                if currentPage == 1 {
                    tokens = fetchedTokens
                } else {
                    tokens.addNewTokens(fetchedTokens)
                }

                hasMore = tokens.totalTokensCount() < allContractTokens.count
                currentPage += 1
                isLoading = false
            }
        }
    }
    
    func initialSearchState() {
        loadInitial()
        allContractTokens.removeAll()
        tokens.clearAll()
    }
    
    func loadInitial() {
        hasMore = true
        isLoading = false
        currentPage = 1
        selectedToken = nil
        error = nil
    }
    
    func isTokenAlreadyImported(tokenId: String) -> Bool {
        let isCIS2TokenSaved = accountSavedCIS2Tokens.filter { $0.contractAddress.index == contractIndex }.contains { $0.tokenId == tokenId }
        let isPLTTokenSaved = CoreDataPLTStore.shared.isPLTTokenSaved(tokenId: tokenId, for: account.address)
        return isCIS2TokenSaved || isPLTTokenSaved
    }
}
