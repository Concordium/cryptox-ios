//
//  RecoverAccountsViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

enum RecoverAccountsViewState {
    case idle, recovering, failed, recoveredNoData
    case success([IdentityDataType], [AccountDataType])
    case partial([IdentityDataType], [AccountDataType], [String])
    
    var isRecovering: Bool {
        switch self {
            case .recovering: return true
            default: return false
        }
    }
}

final class RecoverAccountsViewModel: ObservableObject {
    @Published var state: RecoverAccountsViewState = .idle
    @Published var title: String = "recover_accounts_flow_title".localized
    @Published var subtitle: String = "recover_accounts_flow_subtitle".localized
    @Published var actionButtonTitle: String = "recover_accounts_recover_button_title".localized
    
    private let phrase: RecoveryPhrase?
    private let seedString: IdentifiableString?
    private let defaultProvider: ServicesProvider
    private var cancellables = Set<AnyCancellable>()
    private let recoveryPhraseService: RecoveryPhraseServiceProtocol
    private let accountsService: SeedAccountsService
    private var onAccountInported: () -> Void
    
    init(phrase: RecoveryPhrase?, seedString: IdentifiableString?, defaultProvider: ServicesProvider, onAccountInported: @escaping () -> Void) {
        self.phrase = phrase
        self.seedString = seedString
        self.defaultProvider = defaultProvider
        self.recoveryPhraseService = defaultProvider.recoveryPhraseService()
        self.accountsService = defaultProvider.seedAccountsService()
        self.onAccountInported = onAccountInported
    
        $state.map { state in
            switch state {
                case .idle, .recovering:
                    return "recover_accounts_recover_button_title".localized
                case .failed:
                    return "retry"
                case .recoveredNoData, .success, .partial:
                    return "recover_accounts_connect_wallet_button_title".localized
                    
            }
        }
        .assign(to: \.actionButtonTitle, on: self)
        .store(in: &cancellables)
    }
    
    func recoverAccounts(_ pwHash: String) {
        state = .recovering
        
        Task {
            do {
                var seed: Seed?
                if let phrase {
                    seed = try await recoveryPhraseService.store(recoveryPhrase: phrase, with: pwHash)
                } else if let seedString {
                    seed = try await recoveryPhraseService.store(walletPrivateKey: seedString.value, with: pwHash)
                }
                
                guard let seed else {
                    await MainActor.run {
                        self.state = .failed
                    }
                    return
                }
                let (identities, failedIdentityProviders) = try await defaultProvider.seedIdentitiesService().recoverIdentities(with: seed)
                
                let accounts = try await accountsService.recoverAccounts(
                    for: identities,
                    seed: seed,
                    pwHash: pwHash
                )
                                
                var recoveredIdentitiesBuffer: [IdentityDataType] = []
                
                for identity in identities {
                    let isIdentityNewlyCreated = (identity["recover.isNewlyCreatedKey".localized] as? Bool)!
                    let recoveredIdentity = (identity["recover.identityKey".localized] as? IdentityDataType)!
                    
                    if isIdentityNewlyCreated {
                        recoveredIdentitiesBuffer.append(recoveredIdentity)
                    } else {
                        var identityHasRecoveredAccount = false
                        
                        for account in accounts {
                            if account.identity!.id == recoveredIdentity.id {
                                identityHasRecoveredAccount = true
                            }
                        }
                        
                        if identityHasRecoveredAccount {
                            recoveredIdentitiesBuffer.append(recoveredIdentity)
                        }
                    }
                }
                
                await MainActor.run { [recoveredIdentitiesBuffer] in
                    self.handleIdentities(recoveredIdentitiesBuffer, accounts: accounts, failedIdentitiesProviders: failedIdentityProviders)
                }
            } catch {
                await MainActor.run {
                    self.state = .failed
                }
            }
        }
    }
    
    private func handleIdentities(_ identities: [IdentityDataType], accounts: [AccountDataType], failedIdentitiesProviders: [String]) {
        if !failedIdentitiesProviders.isEmpty {
            var failedIdentitiesProvidersString = ""
            for identityProvider in failedIdentitiesProviders {
                failedIdentitiesProvidersString += "\n* \(identityProvider)"
            }
            
            state = .partial(identities, accounts, failedIdentitiesProviders)
            title = "identityrecovery.status.title.partial".localized
            subtitle = String(format: "identityrecovery.status.message.partial".localized, failedIdentitiesProvidersString)
        } else if identities.isEmpty {
            state = .recoveredNoData
            title = "identityrecovery.status.title.emptyResponse".localized
            subtitle = "identityrecovery.status.message.emptyResponse".localized
        } else {
            state = .success(identities, accounts)
            title = "identityrecovery.status.title.success".localized
            subtitle = "identityrecovery.status.message.success".localized
        }
    }
    
    func showMainFlow() {
        onAccountInported()
    }
}
