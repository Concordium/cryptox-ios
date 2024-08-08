//
//  RecoverAccountsView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.01.2024.
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
    
    private let phrase: RecoveryPhrase
    private let defaultProvider: ServicesProvider
    private var cancellables = Set<AnyCancellable>()
    private let recoveryPhraseService: RecoveryPhraseServiceProtocol
    private let accountsService: SeedAccountsService
    private var onAccountInported: () -> Void
    
    init(phrase: RecoveryPhrase, defaultProvider: ServicesProvider, onAccountInported: @escaping () -> Void) {
        self.phrase = phrase
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
                let seed = try await recoveryPhraseService.store(recoveryPhrase: phrase, with: pwHash)
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

struct RecoverAccountsView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: RecoverAccountsViewModel
    
    @EnvironmentObject var sanityChecker: SanityChecker
    @State var isPasscodeViewShow: Bool = false
    
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(viewModel.title)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                Text(viewModel.subtitle)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 64)
            
            switch viewModel.state {
                case .idle: EmptyView()
                case .recovering: LoaderView
                case .failed: EmptyView()
                case .recoveredNoData: Text("No identities founds")
                case .success(let array, let array2), .partial(let array, let array2, _):
                    IdentityList(identities: array, accounts: array2)
            }
            
            
            Spacer()
            
            Button(action: {
                switch viewModel.state {
                    case .idle, .failed:
                        isPasscodeViewShow.toggle()
                    case .recovering: break
                    case .recoveredNoData, .success, .partial:
                        viewModel.showMainFlow()
                }
            }, label: {
                HStack {
                    Text(viewModel.actionButtonTitle)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .lineSpacing(24)
                        .foregroundColor(Color.Neutral.tint7)
                    Spacer()
                    Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                }
                .padding(.horizontal, 24)
            })
            .frame(height: 56)
            .background(Color.EggShell.tint1)
            .cornerRadius(28, corners: .allCorners)
            .opacity(viewModel.state.isRecovering ? 0 : 1)
            .animation(.snappy, value: viewModel.state.isRecovering)
        }
        .padding()
        .modifier(AppBackgroundModifier())
        .overlay(alignment: .topTrailing) {
            Button(action: {
                switch viewModel.state {
                    case .idle: dismiss()
                    case .recovering: break
                    case .failed: dismiss()
                    case .recoveredNoData, .success, .partial: viewModel.showMainFlow()
                }
            }, label: {
                Image(systemName: "xmark")
                    .font(.callout)
                    .frame(width: 35, height: 35)
                    .foregroundStyle(Color.primary)
                    .background(.ultraThinMaterial, in: .circle)
                    .contentShape(.circle)
            })
            .padding(.top, 12)
            .padding(.trailing, 15)
            .opacity(viewModel.state.isRecovering ? 0 : 1)
            .animation(.snappy, value: viewModel.state.isRecovering)
        }
        .passcodeInput(isPresented: $isPasscodeViewShow, onSuccess: viewModel.recoverAccounts)
    }
    
    @ViewBuilder
    var LoaderView: some View {
        VStack {
            Spacer()
            SwiftUI.ProgressView()
                .frame(alignment: .center)
            Spacer()
        }
    }
}

private struct IdentityList: View {
    let identities: [IdentityDataType]
    let accounts: [AccountDataType]
    
    var body: some View {
        List {
            ForEach(identities, id: \.id) { identity in
                VStack(spacing: 18) {
                    HStack {
                        Text(identity.nickname)
                            .font(.plexSans(size: 14, weight: .regular))
                            .foregroundColor(Color.MineralBlue.tint2)

                        Spacer()
                        Text("Accounts: \(accounts.filter { $0.identity?.id == identity.id }.count)")
                            .font(.plexMono(size: 12, weight: .medium))
                            .foregroundColor(Color.MineralBlue.tint2)
                    }

                    
                    VStack(spacing: 16) {
                        ForEach(accounts, id: \.address) { account in
                            if account.identity!.id == identity.id {
                                HStack {
                                    Text(account.displayName)
                                        .font(.satoshi(size: 16, weight: .medium))
                                        .foregroundColor(Color.Neutral.tint7)
                                    Spacer()
                                    Text(GTU(intValue: account.finalizedBalance).displayValueWithCCDStroke())
                                        .font(.satoshi(size: 16, weight: .medium))
                                        .foregroundColor(Color.Neutral.tint7)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .background(Image("small_card_bg").resizable().scaledToFill())
                .cornerRadius(24)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSpacing(10)
        .listStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
