//
//  SwiftUIView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class AccountTokensListPickerViewModel: ObservableObject {
    @Published var accounts: [AccountDetailAccount] = []
    @Published var error: Error?
    @Published var selectedToken: CXTokenType


    private let storageManager: StorageManagerProtocol
    private let networkManager: NetworkManagerProtocol
    let account: AccountDataType
    
    private let cis2Service: CIS2Service
    
    init(account: AccountDataType, storageManager: StorageManagerProtocol, networkManager: NetworkManagerProtocol, selectedToken: CXTokenType) {
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.account = account
        self.selectedToken = selectedToken
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
    }
    
    @MainActor
    func reload() {
        let tokens = storageManager.getAccountSavedCIS2Tokens(account.address)
        var tmpAccounts: [AccountDetailAccount] = [.ccd(amount: GTU(intValue: account.forecastBalance).displayValue())]
        if !tokens.isEmpty {
            Task {
                do {
                    self.error = nil
                    
                    let balances = try await Self.loadCIS2TokenBalances(tokens, address: account.address, cis2Service: cis2Service)
                    var tmpTokens: [AccountDetailAccount] = []
                    tmpTokens = tokens.compactMap { token -> AccountDetailAccount? in
                        guard let (balances, _) = balances.first(where: { $0.1 == token.contractAddress.index }) else { return nil }
                        guard let balance = balances.first(where: { $0.tokenId == token.tokenId }) else { return nil }
                        return AccountDetailAccount.token(token: token, amount: balance.balance)
                    }
                    
                    tmpAccounts.append(contentsOf: tmpTokens)
                } catch {
                    self.error = error
                }
                self.accounts = tmpAccounts
            }
        }
        
        self.accounts = tmpAccounts
    }
    
    private static func loadCIS2TokenBalances(_ tokens: [CIS2Token], address: String, cis2Service: CIS2Service) async throws -> [([CIS2TokenBalance], Int)] {
        return try await withThrowingTaskGroup(of: ([CIS2TokenBalance], Int).self, body: { group in
            for token in tokens {
                group.addTask {
                    try await (cis2Service.fetchTokensBalance(contractIndex: token.contractAddress.index.string, accountAddress: address, tokenId: token.tokenId), token.contractAddress.index)
                }
            }
            
            var result = [([CIS2TokenBalance], Int)]()
            for try await balance in group {
                result.append(balance)
            }
            return result
        })
    }
}

struct AccountTokensListPicker: View {
    @StateObject var viewModel: AccountTokensListPickerViewModel
    
    var didSelectToken: (AccountDetailAccount) -> Void

    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if viewModel.error != nil {
                Text("Failed to load Tokens")
                    .foregroundColor(.white)
                    .font(.satoshi(size: 17, weight: .semibold))
                    .onTapGesture { viewModel.reload() }
            } else {
                VStack(alignment: .leading) {
                    Text(viewModel.account.displayName + ": " + "select_token".localized)
                        .foregroundColor(.white)
                        .font(.satoshi(size: 19, weight: .bold))
                        .onTapGesture { viewModel.reload() }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 24)
                    List(viewModel.accounts, id: \.id) { account in
                        HStack {
                            TokenPickerView(account: account, isSelected: account.name == viewModel.selectedToken.name)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { didSelectToken(account) }
                            Spacer()
                            
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .onAppear { viewModel.reload() }
                }
            }
        }
        .modifier(AppBackgroundModifier())
    }
}

struct TokenPickerView: View {
    let account: AccountDetailAccount
    var isSelected: Bool = false
    
    var body: some View {
        HStack {
            CCDTokenView(account: account)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .overlay {
            if isSelected {
                RoundedCorner(radius: 24, corners: .allCorners)
                    .stroke(Color.blackAditional, lineWidth: 1)
            }
        }
        .overlay(alignment: .trailing) {
            if isSelected {
                selectionOverlay
            }
        }
    }
    
    private var selectionOverlay: some View {
        Image("icon_selection")
            .padding(.trailing, 12)
    }
}
