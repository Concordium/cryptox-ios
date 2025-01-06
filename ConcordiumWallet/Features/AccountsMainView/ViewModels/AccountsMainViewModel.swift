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

final class AccountsMainViewModel: ObservableObject {
    @Published var accounts = [AccountDataType]()
    @Published var accountViewModels = [AccountPreviewViewModel]()
    @Published var state: AccountsMainViewState = .empty
    @Published var totalBalance = GTU(intValue: 0)
    @Published var atDisposal = GTU(intValue: 0)
    @Published var staked = GTU(intValue: 0)
    @Published var isBackupAlertShown = false
    @Published var dotImageName: String = ""
    @Published var selectedAccount: AccountDataType?
    
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    let defaultProvider = ServicesProvider.defaultProvider()
    private var cancellables = [AnyCancellable]()
    private let walletConnectService: WalletConnectService
    private let defaultCIS2TokenManager: DefaultCIS2TokenManager
    
    init(dependencyProvider: AccountsFlowCoordinatorDependencyProvider, onReload: AnyPublisher<Void, Never>, walletConnectService: WalletConnectService) {
        self.dependencyProvider = dependencyProvider
        self.walletConnectService = walletConnectService
        self.isBackupAlertShown = dependencyProvider.mobileWallet().isLegacyAccount()
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
        let dotImageNumber = Range((1...9)).randomElement()
        self.dotImageName = "dot" + "\(dotImageNumber ?? 1)"
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
        if selectedAccount == nil {
            selectedAccount = accounts.first
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
    
    func changeCurrentAccount(_ account: AccountDataType) {
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
}
