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
                    case .send(let account, let tokenType, let address):
                        SendTokenView(viewModel: .init(
                                        tokenType: tokenType,
                                        account: account,
                                        dependencyProvider: dependencyProvider,
                                        tokenTransferModel: CIS2TokenTransferModel(
                                            tokenType: tokenType,
                                            account: account,
                                            dependencyProvider: dependencyProvider,
                                            notifyDestination: .none,
                                            memo: nil,
                                            onTxSuccess: { _ in },
                                            onTxReject: {}
                                        ),
                                        recepientAddress: address,
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
                        AddTokenView(path: $navigationManager.path,
                                       dependencyProvider: dependencyProvider,
                                       account: account,
                                       onTokenAdded: { isNewTokenAdded = true })
                    case .addTokenDetails(let token):
                        TokenDetailsView(token: token, isAddTokenDetails: true, showRawMd: .constant(false))
                            .modifier(NavigationViewModifier(title: "search.tokens".localized, backAction: {
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
                        
                    case .stakeMain(let account):
                        StakeMainView(account: account)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "Staking") {
                                navigationManager.pop()
                            })
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                    case .stake(let account):
                        showStake(account: account)
                    case .stakeReadMode(let mode, let account):
                        StakeReadMoreView(mode: mode, account: account)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: mode == .validator ? "learn.about.validation".localized : "learn.about.staking".localized) {
                                navigationManager.pop()
                            })
                            .onAppear {
                                notifyTabBarHidden(true)
                            }
                        
                        // MARK: - Validator Flow
                    case .amountInput(let viewModel):
                        ValidatorAmountInputView(viewModel: viewModel)
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
                        
                    case .validatorRequestConfirmation(let viewModel):
                        ValidatorSubmissionView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "baking.receiptconfirmation.submit".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                    case .validatorTransactionStatus(let viewModel):
                        ValidatorTransactionStatusView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "Confirmation"))
                    case .updateValidatorMenu(let viewModel):
                        ValidatorUpdateMenu(viewModel: viewModel)
                            .modifier(NavigationViewModifier(title: "stake.desc.baking.header".localized) {
                                navigationManager.pop()
                            })
                    case .delegationAmountInput(let viewModel):
                        DelegationAmountInputView(viewModel: viewModel)
                            .modifier(NavigationViewModifier(title: "stake".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                    case .delegationStakingMode(let viewModel):
                        DelegationStakingModeView(viewModel: viewModel)
                            .modifier(NavigationViewModifier(title: "staking.mode".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                    case .delegationRequestConfirmation(let viewModel):
                        DelegationSubmissionView(viewModel: viewModel)
                            .environmentObject(navigationManager)
                            .modifier(NavigationViewModifier(title: "stake".localized) {
                                navigationManager.pop()
                            })
                            .onAppear { notifyTabBarHidden(true) }
                    case .delegationTransactionStatus(let viewModel):
                        DelegationTransactionStatusView(viewModel: viewModel)
                            .modifier(NavigationViewModifier(title: "confirmation".localized))
                            .onAppear { notifyTabBarHidden(true) }
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
    
    @ViewBuilder
    func showStake(account: AccountEntity) -> some View {
        
        let transfers = self.dependencyProvider.storageManager().getTransfers(for: account.address).filter { transfer in
            transfer.transferType.isDelegationTransfer
        }
        
        // Check if the account has a baker or delegation
        if account.baker == nil && account.delegation == nil && transfers.count == 0 {
            // If no baker or delegation, show the main stake view
            
            StakeMainView(account: account)
                .environmentObject(navigationManager)
                .modifier(NavigationViewModifier(title: "Stake") {
                    navigationManager.pop()
                })
                .onAppear {
                    notifyTabBarHidden(true)
                }
        } else if account.baker != nil {
            let statusViewModel = ValidatorStakeStatusViewModel(account: account,
                                                                dependencyProvider: dependencyProvider,
                                                                navigationManager: navigationManager)
            // If the account has a baker, show the validator flow
            ValidatorStatusView(viewModel: statusViewModel)
                .environmentObject(navigationManager)
                .modifier(NavigationViewModifier(title: "stake.desc.baking.header".localized) {
                    navigationManager.pop()
                })
                .onAppear {
                    notifyTabBarHidden(true)
                }
        } else if account.delegation != nil || transfers.count > 0 {
            let statusViewModel = DelegationStatusViewModel(account: account,
                                                            dependencyProvider: dependencyProvider,
                                                            navigationManager: navigationManager)
            DelegationStatusView(viewModel: statusViewModel)
                .environmentObject(navigationManager)
                .modifier(NavigationViewModifier(title: "stake".localized) {
                    navigationManager.pop()
                })
                .onAppear {
                    notifyTabBarHidden(true)
                }
        }
    }
}
