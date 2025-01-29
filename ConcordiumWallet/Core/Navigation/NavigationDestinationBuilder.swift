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
    @ObservedObject var viewModel: AccountsMainViewModel
    var dependencyProvider = ServicesProvider.defaultProvider()
    weak var router: AccountsMainViewDelegate?
    @Binding var isNewTokenAdded: Bool
    var onAddressPicked = PassthroughSubject<String, Never>()

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationPaths.self) { destination in
                Group {
                    switch destination {
                    case .accountsOverview:
                        AccountsOverviewView(path: $navigationManager.path, viewModel: viewModel, router: router)
                    case .buy:
                        CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
                            .modifier(NavigationViewModifier(title: "Buy CCD") {
                                navigationManager.pop()
                            })
                    case .manageTokens:
                        if let vm = viewModel.accountDetailViewModel {
                            ManageTokensView(viewModel: vm, path: $navigationManager.path, isNewTokenAdded: $isNewTokenAdded)
                        } else {
                            EmptyView()
                        }
                    case .tokenDetails(let token):
                        if let vm = viewModel.accountDetailViewModel, let selectedAccount = viewModel.selectedAccount {
                            TokenBalanceView(token: token, path: $navigationManager.path, selectedAccount: selectedAccount, viewModel: vm, router: self.router)
                        } else {
                            EmptyView()
                        }
                    case .send:
                        if let selectedAccount = viewModel.selectedAccount {
                            SendTokenView(path: $navigationManager.path,
                                          viewModel: .init(
                                            tokenType: .ccd,
                                            account: selectedAccount,
                                            dependencyProvider: dependencyProvider,
                                            tokenTransferModel: CIS2TokenTransferModel(
                                                tokenType: .ccd,
                                                account: selectedAccount,
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
                        }
                    case .chooseTokenToSend(let transferTokenVM):
                        if let vm = viewModel.accountDetailViewModel {
                            ChooseTokenView(viewModel: vm, transferTokenViewModel: transferTokenVM) {
                                navigationManager.pop()
                            }
                            .modifier(NavigationViewModifier(title: "Choose token", backAction: {
                                navigationManager.pop()
                            }))
                        }
                    case .earn:
                        EmptyView()
                    case .addToken:
                        if let selectedAccount = viewModel.selectedAccount {
                            AddTokenView(
                                path: $navigationManager.path,
                                viewModel: .init(storageManager: dependencyProvider.storageManager(),
                                                 networkManager: dependencyProvider.networkManager(),
                                                 account: selectedAccount),
                                searchTokenViewModel: SearchTokenViewModel(
                                    cis2Service: CIS2Service(
                                        networkManager: dependencyProvider.networkManager(),
                                        storageManager: dependencyProvider.storageManager()
                                    )
                                ),
                                onTokenAdded: { isNewTokenAdded = true }
                            )
                        } else {
                            EmptyView()
                        }
                    case .addTokenDetails(let token):
                        TokenDetailsView(token: token, isAddTokenDetails: true, showRawMd: .constant(false))
                            .modifier(NavigationViewModifier(title: "Add token", backAction: {
                                navigationManager.pop()
                            }))
                    case .activity:
                        if let selectedAccount = viewModel.selectedAccount {
                            TransactionsView(viewModel: TransactionsViewModel(account: selectedAccount, dependencyProvider: ServicesProvider.defaultProvider())) { vm in
                                navigationManager.navigate(to: .transactionDetails(transaction: vm))
                            }
                            .modifier(AppBackgroundModifier())
                            .modifier(NavigationViewModifier(title: "Activity") {
                                navigationManager.pop()
                            })
                        }
                    case .transactionDetails(let transaction):
                        TransactionDetailView(viewModel: transaction)
                            .modifier(NavigationViewModifier(title: "Transaction Details", backAction: {
                                navigationManager.pop()
                            }))
                    case .selectRecipient:
                        if let selectedAccount = viewModel.selectedAccount {
                            SelectRecipientView(viewModel: RecipientListViewModel(storageManager: dependencyProvider.storageManager(), mode: .addressBook, ownAccount: selectedAccount)) { address in
                                onAddressPicked.send(address)
                                navigationManager.pop()
                            }
                            .modifier(NavigationViewModifier(title: "Choose recipient", backAction: {
                                navigationManager.pop()
                            }))
                        }
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
                    }
                }
            }
    }
}
