//
//  AccountDetailView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 29.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt
import Combine

enum AccountDetailAccount: Equatable, Identifiable, Hashable {
    case ccd(amount: String), token(token: CIS2Token, amount: String)
    
    var id: Int {
        switch self {
            case .ccd(let address): return address.hashValue
            case let .token(token, amount): return token.tokenId.hashValue ^ token.contractName.hashValue ^ token.contractAddress.index.hashValue ^ amount.hashValue
        }
    }
    
    var name: String {
        switch self {
            case .ccd: return "ccd"
            case .token(let token, _): return token.metadata.name ?? ""
        }
    }
}

final class AccountDetailViewModel: ObservableObject {
    enum State: String, CaseIterable {
        case accounts, transactions
        
        var locTitle: String {
            self.rawValue.localized
        }
    }
    
    @Published var state: State = .accounts
    @Published var sceneTitle: String = ""
    @Published var accounts: [AccountDetailAccount] = []

    let account: AccountDataType
    let storageManager: StorageManagerProtocol
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    
    private var router: AccountDetailRoutable
    private var cancellables = [AnyCancellable]()

    init(
        router: AccountDetailRoutable,
        account: AccountDataType,
        storageManager: StorageManagerProtocol,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.account = account
        self.storageManager = storageManager
        self.router = router
        sceneTitle = account.displayName
        
        storageManager.subscribeCIS2TokensUpdate(account.address).sink { [weak self] val in
            await self?.reload()
        }.store(in: &cancellables)
    }
    
    @MainActor
    func showImportTokensFlow() {
        self.router.showImportTokenFlow(for: self.account)
    }
    
    @MainActor
    func didTapOnToken(_ token: AccountDetailAccount) {
        switch token {
            case .ccd:
                self.router.showAccountDetailFlow(for: account)
            case .token(let token, _):
                self.router.showCIS2TokenDetailsFlow(token, account: account)
        }
    }
    
    @MainActor
    func didTapOnTx(_ tx: TransactionViewModel) {
        router.showTx(tx)
    }
    
    @MainActor
    func reload() async {
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
}


struct AccountDetailView: View {
    @StateObject var viewModel: AccountDetailViewModel

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    SegmentedPicker(items: AccountDetailViewModel.State.allCases, selection: $viewModel.state) { item in
                        Text(item.locTitle)
                            .foregroundColor(.white)
                            .font(.satoshi(size: 16, weight: .semibold))
                    }
                    
                    switch viewModel.state {
                        case .accounts:
                            List(viewModel.accounts, id: \.id) { account in
                                HStack {
                                    CCDTokenView(account: account)
                                        .listRowBackground(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.didTapOnToken(account)
                                    }
                                    Spacer()
                                    Image("icon_disclosure").resizable().frame(width: 24, height: 24)
                                }.listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                            .refreshable {
                                await viewModel.reload()
                            }
                            
                            Spacer()
                            Button {
                                viewModel.showImportTokensFlow()
                            } label: {
                                Text("add.token".localized)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.black)
                                    .font(.satoshi(size: 17, weight: .semibold))
                                    .padding(.vertical, 11)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                            .padding()
                        case .transactions:
                            TransactionsView(viewModel: .init(account: viewModel.account, dependencyProvider: viewModel.dependencyProvider)) { tx in
                                viewModel.didTapOnTx(tx)
                            }
                    }
                }
                .background(Color.blackSecondary.cornerRadius(24))
                .padding(18)
            }
        }
        .onAppear {
            Task {
                await viewModel.reload()
            }
        }
        .navigationTitle(viewModel.sceneTitle)
        .navigationBarBackButtonHidden(false)
        .modifier(AppBackgroundModifier())
    }
}

struct CCDTokenView: View {
    let account: AccountDetailAccount
    
    var body: some View {
        HStack {
            switch account {
                case .ccd(let amount):
                    Image("icon_ccd")
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text(amount + " CCD")
                        .foregroundColor(.white)
                        .font(.satoshi(size: 15, weight: .medium))
                case .token(let token, let amount):
                    if let url = token.metadata.thumbnail?.url {
                        CryptoImage(url: url.toURL, size: .medium)
                            .aspectRatio(contentMode: .fit)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TokenFormatter()
                            .string(from: BigDecimal(BigInt(stringLiteral: amount), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ","))
                            .foregroundColor(.white)
                        .font(.satoshi(size: 15, weight: .medium))
                        Text(token.metadata.name ?? "")
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        .font(.satoshi(size: 13, weight: .medium))
                    }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
