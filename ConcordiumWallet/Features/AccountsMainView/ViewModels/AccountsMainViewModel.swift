//
//  AccountsMainViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 06.07.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
enum AccountsMainViewState {
    case accounts, createAccount, createIdentity, identityVerification, verificationFailed, empty, saveSeedPhrase
}

final class AccountsMainViewModel: ObservableObject, Hashable, Equatable {
    @Published var accounts = [AccountDataType]()
    @Published var accountViewModels = [AccountPreviewViewModel]()
    @Published var state: AccountsMainViewState = .empty
    @Published var totalBalance = GTU(intValue: 0)
    @Published var atDisposal = GTU(intValue: 0)
    @Published var staked = GTU(intValue: 0)
    @Published var isBackupAlertShown = false
    @Published var selectedAccount: AccountPreviewViewModel?
    
    @Published var isLoadedAccounts: Bool = false
    
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    let defaultProvider = ServicesProvider.defaultProvider()
    private var cancellables = [AnyCancellable]()
    private let walletConnectService: WalletConnectService
    private let defaultCIS2TokenManager: DefaultCIS2TokenManager
    
    init(dependencyProvider: AccountsFlowCoordinatorDependencyProvider, onReload: AnyPublisher<Void, Never>, walletConnectService: WalletConnectService) {
        self.dependencyProvider = dependencyProvider
        self.walletConnectService = walletConnectService
        self.isBackupAlertShown = dependencyProvider.mobileWallet().isLegacyAccount() && AppSettings.isImportedFromFile
        self.defaultCIS2TokenManager = .init(storageManager: dependencyProvider.storageManager(), networkManager: self.dependencyProvider.networkManager())
        
        accounts = dependencyProvider.storageManager().getAccounts().sorted(by: { t1, t2 in
            if (t1.forecastBalance == t2.forecastBalance) {
                return t1.createdTime > t2.createdTime
            }
            return t1.forecastBalance > t2.forecastBalance
        })
        
        onReload.sink { [weak self] _ in
            guard let self = self else { return }
            await self.reload()
        }.store(in: &cancellables)        
    }
    
    @MainActor
    func reload() async {
        accounts = dependencyProvider.storageManager().getAccounts()
        await reloadAccounts()
        refreshPendingIdentities()
        self.identifyPendingAccounts(updatedAccounts: accounts)
        Task {
            checkPendingAccountsStatusesIfNeeded()
        }
        updateData()
        if let lastSelectedAccountAddress = AppSettings.lastSelectedAccountAddress {
            selectedAccount = accountViewModels.first(where: {$0.address == lastSelectedAccountAddress})
        } else if selectedAccount == nil {
            let firstAccount = accounts.first
            selectedAccount = accountViewModels.first(where: {$0.address == firstAccount?.address})
        }
        checkChangesInSelectedAccount()
        isLoadedAccounts = true
    }
    
    func checkChangesInSelectedAccount() {
        let updatedAccountData = accountViewModels.first(where: {$0.address == selectedAccount?.address})
        if updatedAccountData != selectedAccount {
            selectedAccount = updatedAccountData
        }
    }
    
    @MainActor
    private func reloadAccounts() async {
        do {
            self.accounts = try await updateAccountsInfo(self.accounts).sorted(by: { t1, t2 in
                if (t1.forecastBalance == t2.forecastBalance) {
                    return t1.createdTime > t2.createdTime
                }
                return t1.forecastBalance > t2.forecastBalance
            })
        } catch {
            debugPrint(error)
        }
    }
    
    private func updateData() {
        accountViewModels = accounts.map { AccountPreviewViewModel.init(account: $0, tokens: dependencyProvider.storageManager().getAccountSavedCIS2Tokens($0.address)) }
        updateDotImageNames()
        if defaultProvider.mobileWallet().isLegacyAccount() && AppSettings.isImportedFromFile {
            state = .accounts
        } else {
            withAnimation {
                if !defaultProvider.seedMobileWallet().hasSetupRecoveryPhrase {
                    state = .saveSeedPhrase
                } else if dependencyProvider.storageManager().getIdentities().isEmpty {
                    state = .createIdentity
                } else if !dependencyProvider.storageManager().getPendingIdentities().isEmpty {
                    state = .identityVerification
                } else if !dependencyProvider.storageManager().getFailedIdentities().isEmpty && dependencyProvider.storageManager().getConfirmedIdentities().isEmpty {
                    state = .verificationFailed
                } else if accounts.isEmpty {
                    state = .createAccount
                } else {
                    state = .accounts
                }
            }
        }
            totalBalance = GTU(intValue: accounts.reduce(into: 0, { $0 += $1.forecastBalance }))
            atDisposal = GTU(intValue: accounts
                .filter { !$0.isReadOnly }
                .reduce(into: 0, { $0 += $1.forecastAtDisposalBalance }))
            staked = GTU(intValue: accounts.reduce(into: 0, { $0 += ($1.baker?.stakedAmount ?? 0) }))
    }
    
    @MainActor
    private func updateAccountsInfo(_ accounts: [AccountDataType]) async throws -> [AccountDataType] {
        try await dependencyProvider.accountsService().updateAccountsBalances(accounts: accounts).async()
    }
    
    func changeCurrentAccount(_ account: AccountPreviewViewModel) {
        selectedAccount = account
    }
}

/// Accoun finalization logic
extension AccountsMainViewModel {
    @MainActor
    private func checkPendingAccountsStatusesIfNeeded() {
        let pendingAccountsAddresses = dependencyProvider.storageManager().getPendingAccountsAddresses()
        
        guard !pendingAccountsAddresses.isEmpty else { return }
        
        var pendingAccounts: [AccountDataType] = []

        for address in pendingAccountsAddresses {
            guard let account = dependencyProvider.storageManager().getAccount(withAddress: address) else { return }
            pendingAccounts.append(account)
        }

        var pendingAccountStatusRequests = [AnyPublisher<AccountSubmissionStatus, Error>]()

        for account in pendingAccounts {
            if account.submissionId != "" {
                pendingAccountStatusRequests.append(dependencyProvider.accountsService().getState(for: account))
            } else {
                pendingAccountStatusRequests.append(dependencyProvider.identitiesService().getInitialAccountStatus(for: account))
            }
        }

        Publishers.MergeMany(pendingAccountStatusRequests)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveError: { _ in },
                receiveValue: { [weak self] in
                    self?.handleFinalizedAccountsIfNeeded($0)
                })
            .store(in: &cancellables)
    }
    
    private func handleFinalizedAccountsIfNeeded(_ data: [AccountSubmissionStatus]) {
        let finalizedAccounts = data.filter { $0.status == .finalized }.map { $0.account }

        guard !finalizedAccounts.isEmpty else { return }

        if finalizedAccounts.count > 1 {
            AppSettings.needsBackupWarning = true
            finalizedAccounts.forEach { markPendingAccountAsFinalized(account: $0) }
        } else if finalizedAccounts.count == 1, let account = finalizedAccounts.first {
            AppSettings.needsBackupWarning = true
            markPendingAccountAsFinalized(account: account)
        }
    }

    private func markPendingAccountAsFinalized(account: AccountDataType) {
        dependencyProvider.storageManager().removePendingAccount(with: account.address)
        Task {
            do {
                try await defaultCIS2TokenManager.addDefaultCIS2Token(to: account)
                await reload()
            } catch {
                DispatchQueue.main.async {
                    logger.errorLog("failed to add default tokens to account: \(account.address)")
                }
            }
        }
    }
    
    private func identifyPendingAccounts(updatedAccounts: [AccountDataType]) {
        let newPendingAccounts = updatedAccounts
            .filter { $0.transactionStatus == .committed || $0.transactionStatus == .received }
            .map { $0.address }

        for pendingAccount in newPendingAccounts {
            dependencyProvider.storageManager().storePendingAccount(with: pendingAccount)
        }
    }
    
    // TODO: - add check for pending identities
    private func refreshPendingIdentities() {
        dependencyProvider.identitiesService()
                .updatePendingIdentities()
                .sink(
                        receiveError: { error in
                            LegacyLogger.error("Error updating identities: \(error)")
//                            self.identities = self.dependencyProvider.storageManager().getIdentities()
                        },
                        receiveValue: { updatedPendingIdentities in
//                            self.identities = self.dependencyProvider.storageManager().getIdentities()
//                            self.checkIfConfirmedOrFailed()
                        }).store(in: &cancellables)
    }
    
    func updateDotImageNames() {
        let dotImages = ["Dot1", "dot2", "dot3", "dot4", "dot5", "dot6", "dot7", "dot8", "dot9"]
        accountViewModels.enumerated().forEach { index, account in
            account.dotImageIndex = index % dotImages.count + 1
        }
    }
}

extension AccountsMainViewModel {
    // MARK: - Equatable
    static func == (lhs: AccountsMainViewModel, rhs: AccountsMainViewModel) -> Bool {
        return lhs.accounts.map(\.address) == rhs.accounts.map(\.address) &&
        lhs.accounts.map(\.name) == rhs.accounts.map(\.name) &&
        lhs.accounts.map(\.forecastBalance) == rhs.accounts.map(\.forecastBalance) &&
        lhs.accounts.map(\.forecastAtDisposalBalance) == rhs.accounts.map(\.forecastAtDisposalBalance) &&
        lhs.accounts.map(\.identity?.id) == rhs.accounts.map(\.identity?.id) &&
               lhs.totalBalance == rhs.totalBalance &&
               lhs.atDisposal == rhs.atDisposal &&
               lhs.staked == rhs.staked &&
               lhs.isBackupAlertShown == rhs.isBackupAlertShown &&
               lhs.selectedAccount?.address == rhs.selectedAccount?.address
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(accounts.map(\.address))
        hasher.combine(accounts.map(\.name))
        hasher.combine(accounts.map(\.forecastBalance))
        hasher.combine(accounts.map(\.forecastAtDisposalBalance))
        hasher.combine(accounts.map(\.identity?.id))
        hasher.combine(totalBalance)
        hasher.combine(atDisposal)
        hasher.combine(staked)
        hasher.combine(isBackupAlertShown)
        hasher.combine(selectedAccount?.address)
        hasher.combine(selectedAccount?.account?.name)
    }
}
