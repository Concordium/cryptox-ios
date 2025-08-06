//
//  ImportTokenViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
final class ImportTokenViewModel: ObservableObject {
    @State var accountSavedCIS2Tokens: [CIS2Token]
    @Published var tokens: UnifiedTokensResult?
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
    private var cancellables = Set<AnyCancellable>()

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
    
    func saveToken(_ token: UnifiedToken?) {
        guard let token = token else { return }
        saveToken(token)
    }
    
    private func saveToken(_ token: UnifiedToken) {
        switch token {
        case .cis2(let cis2Token):
            guard !storageManager.getAccountSavedCIS2Tokens(account.address).contains(cis2Token) else { return }
            
            do {
                try storageManager.storeCIS2Token(token: cis2Token, address: account.address)
            } catch {
                logger.errorLog(error.localizedDescription)
            }
        case .plt(let pltToken):
            guard !CoreDataPLTStore.shared.isPLTTokenSaved(tokenId: pltToken.tokenID, for: account.address) else {
                return
            }
            let tokenAccountState = TokenAccountState(balance: TokenBalance(decimals: pltToken.tokenState.decimals, value: ""), state: TokenBalanceState(denyList: nil))
            let accountPLTToken = AccountPLTToken(token: pltToken, tokenAccountState: tokenAccountState)
            CoreDataPLTStore.shared.saveTokens([accountPLTToken], for: account.address)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(_):
                        self.error = .tokeSaveFailed
                    }
                }, receiveValue: {})
                .store(in: &cancellables)
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
                    tokens?.addNewTokens(cis2Tokens: fetchedTokens.cis2Tokens, pltTokens: fetchedTokens.pltTokens)
                }

                hasMore = (tokens?.tokens.count ?? 0) < allContractTokens.count
                currentPage += 1
                isLoading = false
            }
        }
    }
    
    func initialSearchState() {
        loadInitial()
        allContractTokens.removeAll()
        tokens?.clearAll()
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
