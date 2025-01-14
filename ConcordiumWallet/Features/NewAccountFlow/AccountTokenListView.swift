//
//  AccountTokenListView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import BigInt

enum TokenListMode {
    case normal
    case manage
}

struct AccountTokenListView: View {
    @ObservedObject var viewModel: AccountDetailViewModel2
    @Binding var showTokenDetails: Bool
    @Binding var showManageTokenList: Bool
    @Binding var selectedToken: AccountDetailAccount?
    
    var mode: TokenListMode
    var onHideToken: ((CIS2Token) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.accounts, id: \.id) { account in
                    tokenListViewCell(account: account)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                }
                HStack(spacing: 8) {
                    Image("settingsGear")
                        .renderingMode(.template)
                        .foregroundStyle(.greyAdditional)
                    Text("Manage token list")
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.greyAdditional)
                    
                }
                .padding(.leading, 24)
                .padding(.top, 8)
                .onTapGesture {
                    showManageTokenList = true
                }
                .opacity(mode == .normal ? 1 : 0)
            }
        }
        .padding(.horizontal, 18)
        .refreshable {
            await viewModel.reload()
        }
        .onAppear {
            Task {
                await viewModel.reload()
            }
        }
        .onAppear {
            showManageTokenList = false
            showTokenDetails = false
            selectedToken = nil
        }
    }
    
    func tokenListViewCell(account: AccountDetailAccount) -> some View {
        HStack(alignment: .center, spacing: 17) {
            switch account {
            case .ccd(let amount):
                Image("onramp_ccd")
                HStack(spacing: 0) {
                    Text("CCD")
                        .font(.satoshi(size: 15, weight: .medium))
                    if (viewModel.account?.baker != nil || viewModel.account?.delegation != nil) && mode == .normal {
                        Text(" · %")
                            .font(.satoshi(size: 15, weight: .medium))
                    }
                }
                
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amount)
                        .font(.satoshi(size: 15, weight: .medium))
                        .tint(.white)
                    Text("23456 EUR")
                        .font(.satoshi(size: 12, weight: .regular))
                        .tint(.MineralBlue.blueish3)
                        .opacity(0.5)
                }
                .opacity(mode == .normal ? 1 : 0)
            case .token(let token, let amount):
                if let url = token.metadata.thumbnail?.url {
                    CryptoImage(url: url.toURL, size: .medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                Text(token.metadata.symbol ?? "")
                    .font(.satoshi(size: 15, weight: .medium))
                Spacer()
                Text(TokenFormatter()
                    .displayStringWithTwoValuesAfterComma(from: BigDecimal(BigInt(stringLiteral: amount), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ","))
                    .font(.satoshi(size: 15, weight: .medium))
                    .tint(.white)
                    .opacity(mode == .normal ? 1 : 0)
                if mode == .manage {
                    Text("Hide token")
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                        .opacity(account.name == "ccd" ? 0 : 1)
                        .onTapGesture {
                            onHideToken?(token)
                        }
                }
            }
            if mode == .normal {
                Image("caretRight")
                    .renderingMode(.template)
                    .foregroundStyle(.grey4)
                    .frame(width: 30, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .onTapGesture {
            if mode == .normal {
                showTokenDetails = true
                selectedToken = account
            }
        }
    }
}

final class AccountDetailViewModel2: ObservableObject {
    enum State: String, CaseIterable {
        case accounts, transactions
        
        var locTitle: String {
            self.rawValue.localized
        }
    }
    
    @Published var state: State = .accounts
    @Published var sceneTitle: String = ""
    @Published var accounts: [AccountDetailAccount] = []
    @Published var totalCooldown: GTU?
    @Published var atDisposal: GTU?
    @Published var isReadOnly = false
    @Published var hasStaked = false
    @Published var stakedValue: GTU?
    
    let account: AccountDataType?
    let storageManager: StorageManagerProtocol
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    
    private var cancellables = [AnyCancellable]()

    init(account: AccountDataType?) {
        self.dependencyProvider = ServicesProvider.defaultProvider()
        self.storageManager = ServicesProvider.defaultProvider().storageManager()

        guard let account else {
            self.account = nil
            return
        }
        self.account = account
        sceneTitle = account.displayName

        if let baker = account.baker, baker.bakerID != -1 {
            self.hasStaked = true
            self.stakedValue = GTU(intValue: baker.stakedAmount )
            
        } else if let delegation = account.delegation {
            self.hasStaked = true
            self.stakedValue = GTU(intValue: Int(delegation.stakedAmount) )
        }
        
        self.atDisposal = GTU(intValue: account.forecastAtDisposalBalance)
        self.totalCooldown = GTU(intValue: account.cooldowns.compactMap { Int($0.amount) }.reduce(0, +))
        self.isReadOnly = account.isReadOnly
        
        storageManager.subscribeCIS2TokensUpdate(account.address).sink { [weak self] val in
            await self?.reload()
        }.store(in: &cancellables)
    }
//    
//    @MainActor
//    func showImportTokensFlow() {
//        self.router.showImportTokenFlow(for: self.account)
//    }
//    
//    @MainActor
//    func didTapOnToken(_ token: AccountDetailAccount) {
//        switch token {
//            case .ccd:
//                self.router.showAccountDetailFlow(for: account)
//            case .token(let token, _):
//                self.router.showCIS2TokenDetailsFlow(token, account: account)
//        }
//    }
//    
//    @MainActor
//    func didTapOnTx(_ tx: TransactionViewModel) {
//        router.showTx(tx)
//    }
    
    @MainActor
    func reload() async {
        guard let account else { return }
        let tokens = storageManager.getAccountSavedCIS2Tokens(account.address)
        let cis2Service = CIS2Service(networkManager: self.dependencyProvider.networkManager(), storageManager: storageManager)
        if !tokens.isEmpty {
            var tmpAccounts: [AccountDetailAccount] = [.ccd(amount: GTU(intValue: account.forecastBalance).displayValue())]
            do {
                let balances = try await Self.loadCIS2TokenBalances(tokens, address: account.address, cis2Service: cis2Service)
                var tmpTokens: [AccountDetailAccount] = []
                tmpTokens = tokens.compactMap { token -> AccountDetailAccount? in
                    let contractTokenBalances = balances.filter { $1 == token.contractAddress.index }.map(\.0).flatMap { $0 }
                    guard let tokenBalance = contractTokenBalances.first(where: { $0.tokenId == token.tokenId }) else { return nil }
                    return AccountDetailAccount.token(token: token, amount: tokenBalance.balance)
                }
                
                tmpAccounts.append(contentsOf: tmpTokens)
            } catch { }
            
            self.accounts = tmpAccounts
        } else {
            self.accounts = [.ccd(amount: GTU(intValue: account.forecastBalance).displayValue())]
        }
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
    
    func removeToken(_ token: CIS2Token) {
        guard let account else { return }
        do {
            try storageManager.removeCIS2Token(token: token, address: account.address)
            //            self.onDismiss()
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}
