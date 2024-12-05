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
    
    private let transactionsLoadingHandler: TransactionsLoadingHandler
    private var cancellables = [AnyCancellable]()
    
    init(account: AccountDataType, dependencyProvider: AccountsFlowCoordinatorDependencyProvider) {
        transactionsLoadingHandler = TransactionsLoadingHandler(account: account, balanceType: .balance, dependencyProvider: dependencyProvider)
        
        $tmpTransactions.sink { models in
            self.pairs = Dictionary.init(grouping: models, by: {
                let components = Calendar.current.dateComponents([.day, .month, .year], from: $0.date)
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
}

struct TransactionsView: View {
    @StateObject var viewModel: TransactionsViewModel
    
    let onTxTap: (TransactionViewModel) -> Void
    
    var body: some View {
        if viewModel.pairs.isEmpty {
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
        } else {
            List {
                ForEach(viewModel.pairs.map { $0.key }.sorted(by: >), id: \.self) { date in
                    Section(
                        header:
                            HStack {
                                Spacer()
                                Text(Self.relativeDate(date))
                                    .font(.satoshi(size: 14, weight: .medium))
                                    .foregroundColor(Color.blackAditional)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                    ) {
                        ForEach(viewModel.pairs[date]!, id: \.identifier) { tx in
                            TransactionListView(viewModel: .init(tx))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.onTxTap(tx)
                                }
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                
                if viewModel.hasMoreItems && !viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                Task {
                                    await viewModel.loadMore()
                                }
                            }
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
                
            }
            .onAppear { Task { await viewModel.reload() } }
            .listStyle(.plain)
            .refreshable { await viewModel.reload() }
        }
    }
    
    private static func relativeDate(_ date: Date) -> String {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter.string(from: date)
    }
}
