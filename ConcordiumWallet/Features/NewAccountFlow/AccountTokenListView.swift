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
    @ObservedObject var viewModel: AccountDetailViewModel
    @Binding var showManageTokenList: Bool
    @Binding var path: [NavigationPaths]
    @State private var selectedAccountID: Int?
    @State private var managePressed: Bool = false
    @State private var hideTokenID: Int?
    
    var pressedButtonColor: Color {
        managePressed ? Color.buttonPressed : .greyAdditional
    }
    var mode: TokenListMode
    var onHideToken: ((CIS2Token) -> Void)?
    var euroAmount: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(viewModel.accounts, id: \.id) { account in
                    tokenListViewCell(account: account)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                        .transition(.opacity)
                }
                HStack(spacing: 8) {
                    Image("settingsGear")
                        .renderingMode(.template)
                        .foregroundStyle(pressedButtonColor)
                    Text("Manage token list")
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(pressedButtonColor)
                    
                }
                .padding(.leading, 24)
                .padding(.vertical, 8)
                .onTapGesture {
                    managePressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        managePressed = false
                        showManageTokenList = true
                    }
                }
                .opacity(mode == .normal ? 1 : 0)
            }
            .animation(.easeInOut, value: viewModel.accounts)
        }
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
        }
    }
    
    func tokenListViewCell(account: AccountDetailAccount) -> some View {
        HStack(alignment: .center, spacing: 17) {
            switch account {
            case .ccd(let amount):
                Image("ccd")
                    .resizable()
                    .frame(width: 40, height: 40)
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
                    Text(amount.displayValueWithTwoNumbersAfterDecimalPoint())
                        .font(.satoshi(size: 15, weight: .medium))
                        .tint(.white)
                    Text("\(viewModel.ccdEuroEquivalent)")
                        .font(.satoshi(size: 12, weight: .regular))
                        .tint(.MineralBlue.blueish3)
                        .opacity(0.5)
                }
                .opacity(mode == .normal ? 1 : 0)
            case .token(let token, let amount):
                if let url = token.metadata.thumbnail?.url {
                    CryptoImage(url: url.toURL, size: .custom(width: 40, height: 40))
                        .aspectRatio(contentMode: .fit)
                }
                Text(token.metadata.symbol ?? token.metadata.name ?? "")
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
                        .foregroundStyle(hideTokenID == token.id ? .buttonPressed : Color.MineralBlue.blueish2)
                        .opacity(account.name == "ccd" ? 0 : 1)
                        .onTapGesture {
                            hideTokenID = token.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                hideTokenID = nil
                                onHideToken?(token)
                            }
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
        .background(selectedAccountID == account.id ? .selectedCell : Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .onTapGesture {
            if mode == .normal {
                selectedAccountID = account.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    selectedAccountID = nil
                    path.append(.tokenDetails(token: account, viewModel))
                }
            }
        }
    }
}

final class AccountDetailViewModel: ObservableObject, Hashable, Equatable {
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
    @Published var ccdEuroEquivalent: String = "0.00 EUR"
    
    var account: AccountDataType? {
        didSet {
            Task { await reload() }
        }
    }
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
        
        //TODO: - use `account.isStaking` intead
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
            Task { @MainActor in
                await self?.reload()
            }
        }.store(in: &cancellables)
    }
    
    @MainActor
    func reload() async {
        guard let account else { return }
        let tokens = storageManager.getAccountSavedCIS2Tokens(account.address)
        let cis2Service = CIS2Service(networkManager: self.dependencyProvider.networkManager(), storageManager: storageManager)
        if !tokens.isEmpty {
            var tmpAccounts: [AccountDetailAccount] = [.ccd(amount: GTU(intValue: account.forecastBalance))]
            do {
                let balances = try await Self.loadCIS2TokenBalances(tokens, address: account.address, cis2Service: cis2Service)
                let tmpTokens: [AccountDetailAccount] = tokens.compactMap { token -> AccountDetailAccount? in
                    let contractTokenBalances = balances.filter { $1 == token.contractAddress.index }.map(\.0).flatMap { $0 }
                    guard let tokenBalance = contractTokenBalances.first(where: { $0.tokenId == token.tokenId }) else { return nil }
                    return AccountDetailAccount.token(token: token, amount: tokenBalance.balance)
                }
                
                tmpAccounts.append(contentsOf: tmpTokens)
            } catch { }
            
            self.accounts = tmpAccounts
        } else {
            self.accounts = [.ccd(amount: GTU(intValue: account.forecastBalance))]
        }
        getEuroValueForCCD()
    }
    
    func getEuroValueForCCD() {
        guard let account else { return }
        let ccd = GTU(intValue: account.forecastBalance)
        ServicesProvider.defaultProvider().stakeService().getChainParameters()
            .sink(receiveCompletion: { completionResult in
                switch completionResult {
                default:
                    break
                }
            }, receiveValue: { [weak self] chainParameters in
                let microGTUPerEuro = chainParameters.microGTUPerEuro
                let euroEquivalent = Double(ccd.intValue) * (Double(microGTUPerEuro.denominator) / Double(microGTUPerEuro.numerator))
                let rounded = (euroEquivalent * 100).rounded() / 100
                self?.ccdEuroEquivalent = "\(rounded.string) EUR"
            })
            .store(in: &cancellables)
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
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}

extension AccountDetailViewModel {
    // MARK: - Equatable
    static func == (lhs: AccountDetailViewModel, rhs: AccountDetailViewModel) -> Bool {
        return lhs.state.rawValue == rhs.state.rawValue &&
        lhs.sceneTitle == rhs.sceneTitle &&
        lhs.accounts.map(\.id) == rhs.accounts.map(\.id) &&
        lhs.totalCooldown?.intValue == rhs.totalCooldown?.intValue &&
        lhs.atDisposal?.intValue == rhs.atDisposal?.intValue &&
        lhs.isReadOnly == rhs.isReadOnly &&
        lhs.hasStaked == rhs.hasStaked &&
        lhs.stakedValue?.intValue == rhs.stakedValue?.intValue &&
        lhs.ccdEuroEquivalent == rhs.ccdEuroEquivalent
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(state.rawValue)
        hasher.combine(sceneTitle)
        hasher.combine(accounts.map(\.id))
        hasher.combine(totalCooldown?.intValue)
        hasher.combine(atDisposal?.intValue)
        hasher.combine(isReadOnly)
        hasher.combine(hasStaked)
        hasher.combine(stakedValue?.intValue)
        hasher.combine(ccdEuroEquivalent)
    }
}
