//
//  NavigationDestinationBuilder.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct NavigationDestinationBuilder: ViewModifier {
    @EnvironmentObject var navigationManager: NavigationManager
    var dependencyProvider = ServicesProvider.defaultProvider()
    weak var router: AccountsMainViewDelegate?
    @State var isNewTokenAdded: Bool = false
    var onAddressPicked = PassthroughSubject<String, Never>()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                notifyTabBarHidden(false)
            }
            .navigationDestination(for: NavigationPaths.self) { destination in
                Group {
                    // General navigation flow
                    switch destination {
                    case .accountsOverview(let viewModel):
                        AccountsOverviewView(path: $navigationManager.path, viewModel: viewModel, router: router)
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                    case .buy:
                        CCDOnrampView(dependencyProvider: dependencyProvider)
                            .modifier(NavigationViewModifier(title: "Buy CCD") {
                                navigationManager.pop()
                            })
                    case .manageTokens(let viewModel):
                        if let account = viewModel.selectedAccount?.account {
                            let vm = AccountDetailViewModel(account: account)
                            ManageTokensView(viewModel: vm, path: $navigationManager.path, isNewTokenAdded: $isNewTokenAdded)
                                .onAppear {
                                    notifyTabBarHidden(true)
                                }
                        } else {
                            EmptyView()
                        }
                    case .tokenDetails(let token, let viewModel):
                        if let account = viewModel.account {
                            TokenBalanceView(token: token, path: $navigationManager.path, selectedAccount: account, viewModel: viewModel, router: self.router)
                        } else {
                            EmptyView()
                        }
                        
                    case .send(let account):
                        SendTokenView(path: $navigationManager.path,
                                      viewModel: .init(
                                        tokenType: .ccd,
                                        account: account,
                                        dependencyProvider: dependencyProvider,
                                        tokenTransferModel: CIS2TokenTransferModel(
                                            tokenType: .ccd,
                                            account: account,
                                            dependencyProvider: dependencyProvider,
                                            notifyDestination: .none,
                                            memo: nil,
                                            onTxSuccess: { _ in },
                                            onTxReject: {}
                                        ),
                                        onRecipientPicked: onAddressPicked.eraseToAnyPublisher()))
                        .modifier(NavigationViewModifier(title: "Send", backAction: {
                            navigationManager.pop()
                        }))
                        .onAppear {
                            notifyTabBarHidden(true)
                        }
                    case .chooseTokenToSend(let transferTokenVM, let viewModel):
                        ChooseTokenView(viewModel: viewModel, transferTokenViewModel: transferTokenVM) {
                            navigationManager.pop()
                        }
                        .modifier(NavigationViewModifier(title: "Choose token", backAction: {
                            navigationManager.pop()
                        }))
                    case .addToken(let account):
                        AddTokenView(
                            path: $navigationManager.path,
                            viewModel: .init(storageManager: dependencyProvider.storageManager(),
                                             networkManager: dependencyProvider.networkManager(),
                                             account: account),
                            searchTokenViewModel: SearchTokenViewModel(
                                cis2Service: CIS2Service(
                                    networkManager: dependencyProvider.networkManager(),
                                    storageManager: dependencyProvider.storageManager()
                                )
                            ),
                            onTokenAdded: { isNewTokenAdded = true }
                        )
                    case .addTokenDetails(let token):
                        TokenDetailsView(token: token, isAddTokenDetails: true, showRawMd: .constant(false))
                            .modifier(NavigationViewModifier(title: "Add token", backAction: {
                                navigationManager.pop()
                            }))
                    case .activity(let account):
                        TransactionsView(viewModel: TransactionsViewModel(account: account, dependencyProvider: ServicesProvider.defaultProvider())) { vm in
                            navigationManager.navigate(to: .transactionDetails(transaction: vm))
                        }
                        .modifier(AppBackgroundModifier())
                        .modifier(NavigationViewModifier(title: "Activity") {
                            navigationManager.pop()
                        })
                    case .transactionDetails(let transaction):
                        TransactionDetailView(viewModel: transaction)
                            .modifier(NavigationViewModifier(title: "Transaction Details", backAction: {
                                navigationManager.pop()
                            }))
                    case .selectRecipient(let account, let mode):
                        SelectRecipientView(viewModel: RecipientListViewModel(storageManager: dependencyProvider.storageManager(), mode: mode, ownAccount: account), onRecipientSelected: { address in
                            onAddressPicked.send(address)
                            navigationManager.pop()
                        }, onBackTapped: {
                            navigationManager.pop()
                        })
                        .environmentObject(navigationManager)
                    case .confirmTransaction(let vm):
                        ConfirmTransactionView(viewModel: vm, path: $navigationManager.path)
                            .modifier(NavigationViewModifier(title: "Confirmation", backAction: {
                                navigationManager.pop()
                            }))
                    case .transferSendingStatus(let vm):
                        TransferSendingStatusView(viewModel: vm)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "Sending", backAction: {
                                navigationManager.reset()
                            }))
                    case .addRecipient(let mode):
                        AddRecipientView(viewModel: AddRecipientViewModel(dependencyProvider: ServicesProvider.defaultProvider(), mode: mode)) {
                            navigationManager.pop()
                        }
                    case .receive(let account):
                        AccountQRView(account: account)
                            .modifier(NavigationViewModifier(title: "Receive funds", backAction: {
                                navigationManager.pop()
                            }))
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                        
                    case .earnMain(let account):
                        EarnMainView(account: account)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "Earn") {
                                navigationManager.pop()
                            })
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                    case .earn(let account):
                        showEarn(account: account)
                    case .earnReadMode(let mode, let account):
                        EarnReadMoreView(mode: mode, account: account)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: mode == .validator ? "learn.about.validation".localized : "learn.about.earning".localized) {
                                navigationManager.pop()
                            })
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                        
                        // MARK: - Validator Flow
                    case .amountInput(let viewModel):
                        EarnValidatorAmountInputView(viewModel: viewModel)
                            .modifier(NavigationViewModifier(title: "baking.inputamount.title.create".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                        
                    case .openningPool(let viewModel):
                        OpenPoolView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "validator.opening.pool.title".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                        
                    case .commissionSettings(let viewModel):
                        ComissionSettingsView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "validator.commission.title".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                        
                    case .metadataUrl(let viewModel):
                        ValidatorMetadataView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "validator.metadata.title".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                        
                    case .generateKey(let viewModel):
                        ValidatorGenerateKeysView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "validator.validator.keys.title".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                        
                    case .requestConfirmation(let viewModel):
                        ValidatorSubmissionView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "baking.receiptconfirmation.submit".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                    case .validatorTransactionStatus(let viewModel):
                        ValidatorTransactionStatusView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "Confirmation") {
                                navigationManager.pop()
                            })

                    default:
                        EmptyView()
                    }
                }
            }
    }

    func notifyTabBarHidden(_ isHidden: Bool) {
        let currentState = UserDefaults.standard.bool(forKey: "isTabBarHidden")
        if currentState != isHidden {
            UserDefaults.standard.setValue(isHidden, forKey: "isTabBarHidden")
            NotificationCenter.default.post(name: .hideTabBar, object: nil, userInfo: ["isHidden": isHidden])
        }
    }
    
    func showEarn(account: AccountDataType) -> some View {
        guard let accountEntity = account as? AccountEntity else { return AnyView(EmptyView()) }
        
        // Check if the account has a baker or delegation
        if account.baker == nil && account.delegation == nil {
            // If no baker or delegation, show the main earn view
            return AnyView(
                EarnMainView(account: accountEntity)
                    .environmentObject(navigationManager)
                    .modifier(NavigationViewModifier(title: "Earn") {
                        navigationManager.pop()
                    })
                    .onAppear {
                        notifyTabBarHidden(true)
                    }
            )
        } else if account.baker != nil {
            // If the account has a baker, show the validator flow
            return AnyView(
                ValidatorMainView(viewModel: ValidatorViewModel(account: accountEntity, dependencyProvider: dependencyProvider, navigationManager: navigationManager))
                    .modifier(NavigationViewModifier(title: "Validator", backAction: {
                        navigationManager.pop()
                    }))
                    .onAppear {
                        notifyTabBarHidden(true)
                    }
            )
        } else {
            // Otherwise, just show an empty view (or a different case if needed)
            return AnyView(EmptyView())
        }
    }
}
