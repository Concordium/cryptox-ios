//
//  ShieldedAccountsViewModel.swift
//  CryptoX
//
//  Created by Max on 24.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import BigInt

struct AccountViewData: Identifiable {
    enum Balance: Equatable {
        case decrypted(BigDecimal)
        case encrypted
        
        var title: String {
            switch self {
            case .decrypted(let gTU):
                return TokenFormatter().plainString(from: gTU) + " CCD"
            case .encrypted:
                return "*** ***"
            }
        }
        
        var isZero: Bool {
            switch self {
            case .decrypted(let gTU):
                return gTU.value.isZero
            case .encrypted:
                return true
            }
        }
        
        var value: BigDecimal {
            switch self {
            case .decrypted(let bigDecimal): return bigDecimal
            case .encrypted: return .zero
            }
        }
    }
    
    let id: String
    let displayname: String
    let address: String
    let balance: Balance
    let createdTime: Date
    
    init(account: AccountDataType, balance: Balance) {
        self.id = account.address
        self.displayname = account.displayName
        self.address = account.address
        self.balance = balance
        self.createdTime = account.createdTime
    }
}

@MainActor
final class ShieldedAccountsViewModel: ObservableObject {
    enum State {
        case loadingInitial
        case loaded([AccountViewData])
        case noAccounts
    }
    @Published var state: State = .loadingInitial
    
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let passwordDelegate: RequestPasswordDelegate
    
    init(dependencyProvider: AccountsFlowCoordinatorDependencyProvider, passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate()) {
        self.dependencyProvider = dependencyProvider
        self.passwordDelegate = passwordDelegate
        
        reloadItems()
    }
    
    public func handleUnshieldSuccess(_ account: AccountEntity) {
        switch state {
        case .loaded(let array):
            var newArr: [AccountViewData] = array
            newArr.removeAll(where: { $0.address == account.address })
            self.state = .loaded(newArr)
        case .noAccounts, .loadingInitial:
            break
        }
    }
    
    public func reloadItems() {
        Task.detached { @MainActor in
            let accounts = await self.fetchUpdatedAccounts(accountsService: self.dependencyProvider.accountsService(), storageManager: self.dependencyProvider.storageManager())
            await self.updateAccounts(accounts)
        }
    }
    
    public func getUnshieldAccount(_ account: AccountViewData) -> AccountEntity? {
        dependencyProvider.storageManager().getAccounts().first(where: { $0.address == account.address }) as? AccountEntity
    }
    
    @MainActor
    private func updateAccounts(_ accounts: [any AccountDataType]) async {
            let accountModels = accounts.map { account in
                let isLocked = account.encryptedBalanceStatus == .partiallyDecrypted || account.encryptedBalanceStatus == .encrypted
                if isLocked {
                    let inputEncryptedAmount = self.dependencyProvider.transactionsService().getInputEncryptedAmount(for: account)
                    if let aggEncryptedAmount = inputEncryptedAmount.aggEncryptedAmount, aggEncryptedAmount != ShieldedAmountEntity.zeroValue {
                        return AccountViewData(account: account, balance: .encrypted)
                    }
                }
                
                return AccountViewData(account: account, balance: isLocked ? .encrypted : .decrypted(BigDecimal(BigInt.init(integerLiteral: Int64(account.finalizedEncryptedBalance)), 6)))
            }
                .filter { accountData in
                    switch accountData.balance {
                    case .encrypted: return true
                    case .decrypted(let value): return !value.value.isZero
                    }
                }
                .sorted(by: { t1, t2 in
                    if (t1.balance == t2.balance) {
                        return t1.createdTime > t2.createdTime
                    }
                    return t1.balance.value.value > t2.balance.value.value
                })
            
        self.state = accountModels.isEmpty ? .noAccounts : .loaded(accountModels)
    }
    
    @MainActor
    func decryptBalances(_ seed: String) {
        Task.detached { @MainActor in
            let accounts = await self.fetchShieldedAndSaveedAccounts(accountsService: self.dependencyProvider.accountsService(), storageManager: self.dependencyProvider.storageManager(), seed: seed)
            await self.updateAccounts(accounts)
        }
    }
    
    @MainActor
    func decryptAndStoreShieldedAmount(for account: AccountDataType, seed: String) {
        Task {
            let acc = try await dependencyProvider.accountsService().updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: .balance)
            let balances = [acc.encryptedBalance?.selfAmount ?? ""] + (acc.encryptedBalance?.incomingAmounts ?? [])
            let decryptedAmounts = try await self.dependencyProvider.mobileWallet().decryptEncryptedAmounts(from: acc, balances, pwHash: seed)
            decryptedAmounts.map { (encryptedValue, decryptedValue) -> ShieldedAmountType in
                ShieldedAmountTypeFactory.create().with(account: acc,
                                                        encryptedValue: encryptedValue,
                                                        decryptedValue: String(decryptedValue),
                                                        incomingAmountIndex: -1)
            }
            .forEach { (shieldedAmount) in
                _ = try? self.dependencyProvider.storageManager().storeShieldedAmount(amount: shieldedAmount)
            }
        }
    }
    
    @MainActor
    func fetchShieldedAndSaveedAccounts(accountsService: any AccountsServiceProtocol, storageManager: any StorageManagerProtocol, seed: String) async -> [AccountDataType] {
        precondition(Thread.isMainThread)
        return await withTaskGroup(of: Optional<AccountDataType>.self) { group in
            for account in storageManager.getAccounts() {
                group.addTask {
                    try? await self.decryptAndStoreShieldedAmount(for: account, seed: seed)
                }
            }
            
            return await group.reduce(into: []) { array, result in
                if let account = result {
                    array.append(account)
                }
            }
        }
    }
    
    @MainActor
    func fetchUpdatedAccounts(accountsService: any AccountsServiceProtocol, storageManager: any StorageManagerProtocol) async -> [AccountDataType] {
        precondition(Thread.isMainThread)
        return await withTaskGroup(of: Optional<AccountDataType>.self) { group in
            for account in storageManager.getAccounts() {
                group.addTask {
                    try? await accountsService.updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: .balance)
                }
            }
            
            return await group.reduce(into: []) { array, result in
                if let account = result {
                    array.append(account)
                }
            }
        }
    }
    
    @MainActor
    func decryptAndStoreShieldedAmount(for account: AccountDataType, seed: String) async throws -> AccountDataType {
        let acc = try await dependencyProvider.accountsService().updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: .balance)
        let balances = [acc.encryptedBalance?.selfAmount ?? ""] + (acc.encryptedBalance?.incomingAmounts ?? [])
        let decryptedAmounts = try await self.dependencyProvider.mobileWallet().decryptEncryptedAmounts(from: acc, balances, pwHash: seed)
        decryptedAmounts.map { (encryptedValue, decryptedValue) -> ShieldedAmountType in
            ShieldedAmountTypeFactory.create().with(account: acc,
                                                    encryptedValue: encryptedValue,
                                                    decryptedValue: String(decryptedValue),
                                                    incomingAmountIndex: -1)
        }
        .forEach { (shieldedAmount) in
            _ = try? self.dependencyProvider.storageManager().storeShieldedAmount(amount: shieldedAmount)
        }
        return try await dependencyProvider.accountsService().updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: .balance)
    }
}
