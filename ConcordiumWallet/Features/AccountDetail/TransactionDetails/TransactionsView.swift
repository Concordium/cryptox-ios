//
//  TransactionsView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class TransactionsViewModel: ObservableObject {
    @Published var pairs = [Date: [TransactionViewModel]]()
    @Published var tmpTransactions = [TransactionViewModel]()
    
    @Published var hasMoreItems: Bool = true
    @Published var isLoading: Bool = false
    @Published var shouldShowAlert: Bool = false
    
    private var error: Error?
    private let transactionsLoadingHandler: TransactionsLoadingHandler
    private var cancellables = [AnyCancellable]()
    private let accountsService: AccountsServiceProtocol
    private let account: AccountDataType
    
    init(account: AccountDataType, dependencyProvider: AccountsFlowCoordinatorDependencyProvider) {
        self.accountsService = ServicesProvider.defaultProvider().accountsService()
        self.account = account
        transactionsLoadingHandler = TransactionsLoadingHandler(account: account, balanceType: .balance, dependencyProvider: dependencyProvider)
        
        $tmpTransactions.sink { models in
            self.pairs = Dictionary(grouping: models, by: { transaction in
                let components = Calendar.current.dateComponents([.year, .month], from: transaction.date)
                return Calendar.current.date(from: components)!
            })
        }.store(in: &cancellables)
    }
    
    @MainActor
    func reload() async {
        hasMoreItems = true
        isLoading = true
        do {
            let tx = try await transactionsLoadingHandler.getTransactions().async().0
            self.tmpTransactions = tx
            isLoading = false
        } catch {
            isLoading = false
            hasMoreItems = false
        }
    }
    
    @MainActor
    func loadMore() async {
        if isLoading { return }
        if !hasMoreItems { return }
        
        self.isLoading = true
        
        guard let lastTx = self.tmpTransactions.last else {
            self.hasMoreItems = false
            self.isLoading = false
            return
        }
        
        do {
            let tx = try await transactionsLoadingHandler.getTransactions(startingFrom: lastTx).async().0
            hasMoreItems = !tx.isEmpty
            self.tmpTransactions = self.tmpTransactions + tx
        } catch {
            
        }
        isLoading = false
    }
    
    func gtuDrop() {
        accountsService.gtuDrop(for: account.address)
                .mapError(ErrorMapper.toViewError)
                .sink(receiveError: { [weak self] in
                    self?.shouldShowAlert = true
                    self?.error = $0
                }, receiveValue: { [weak self] _ in
                    self?.updateTransfers()
                })
                .store(in: &cancellables)
        updateTransfers()
    }
    
    fileprivate func updateTransfers() {
        let delegate = DummyRequestPasswordDelegate()
        accountsService.updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: .balance, requestPasswordDelegate: delegate)
            .mapError(ErrorMapper.toViewError)
            .sink(receiveError: { [weak self] error in
                self?.shouldShowAlert = true
                self?.error = error
            }, receiveValue: { [weak self] account in
                // We cannot get transactions from server before we have updated our
                // local store of transactions in the updateAccountsBalances call
                Task { await self?.reload() }
            }).store(in: &cancellables)
    }
    
    func alertOptions() -> SwiftUIAlertOptions {
        let okAction = SwiftUIAlertAction(name: "errorAlert.okButton".localized, completion: nil, style: .styled)
        return .init(title: "errorAlert.title".localized, message: error?.localizedDescription ?? "airdrop.error.message".localized, actions: [okAction])
    }
}

struct TransactionsView: View {
    @StateObject var viewModel: TransactionsViewModel
    
    let onTxTap: (TransactionDetailViewModel) -> Void
    
    var body: some View {
        if viewModel.pairs.isEmpty {
            VStack {
                Spacer()
                VStack {
                    Image("ico_empty_tx")
                        .resizable()
                        .frame(width: 80, height: 80)
                    Text("transactions_empty_state_title".localized)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundColor(Color.blackAditional)
                        .multilineTextAlignment(.center)
                }
                .onAppear { Task { await viewModel.reload() } }
                Spacer()
#if ENABLE_GTU_DROP
                if !viewModel.isLoading {
                    RoundedButton(action: {
                        viewModel.gtuDrop()
                    }, title: "accountDetails.testnetGtuDropButtonTitle".localized)
                }
#endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, pinnedViews: .sectionHeaders) {
                    ForEach(viewModel.pairs.keys.sorted(by: >), id: \.self) { monthDate in
                        // Month Header (displayed once for all transactions in the same month)
                        Text(Self.relativeMonth(monthDate))
                            .font(.satoshi(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Group transactions by day within the current month
                        let transactionsByDay = Dictionary(grouping: viewModel.pairs[monthDate]!, by: { transaction in
                            let components = Calendar.current.dateComponents([.day, .month, .year], from: transaction.date)
                            return Calendar.current.date(from: components)!
                        })
                        let sortedArrayOfDays = transactionsByDay.keys.sorted(by: >)

                        // Iterate over days within the month
                        ForEach(sortedArrayOfDays, id: \.self) { dayDate in
                            // Day Header
                            let isFirstDate = dayDate == sortedArrayOfDays.first
                            Text(Self.relativeDate(dayDate))
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
                                .padding(.top, isFirstDate ? 4 : 20)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Transactions for the day
                            ForEach(transactionsByDay[dayDate]!, id: \.identifier) { tx in
                                Button(action: {
                                    self.onTxTap(TransactionDetailViewModel(transaction: tx))
                                }, label: {
                                    TransactionListView(viewModel: .init(tx))
                                        .contentShape(.rect)
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Loading indicator
                    if viewModel.hasMoreItems && !viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .onAppear {
                                    Task {
                                        await viewModel.loadMore()
                                    }
                                }
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .modifier(AlertModifier(alertOptions: viewModel.alertOptions(), isPresenting: $viewModel.shouldShowAlert))
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .onAppear { Task { await viewModel.reload() } }
            .listStyle(.plain)
            .refreshable { await viewModel.reload() }
        }
    }
    
    private static func relativeDate(_ date: Date) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .none
        relativeDateFormatter.dateFormat = "d MMM"
        return relativeDateFormatter.string(from: date)
    }
    
    private static func relativeMonth(_ date: Date) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .none
        relativeDateFormatter.dateFormat = "MMMM"
        return relativeDateFormatter.string(from: date)
    }
}
