//
//  TransferSendingStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct TransferSendingStatusView: View {
    @ObservedObject var viewModel: TransferTokenConfirmViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var hasStartedTransaction = false
    @State private var isTransactionDetailsVisible: Bool = true
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 30) {
                LottieLoadingAnimation(isTransactionExecuting: $viewModel.isLoading, error: $viewModel.error)
                
                Divider()
                    .background(.white.opacity(0.1))
                
                VStack(spacing: 8) {
                    Text(viewModel.transactionStatusLabel)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .transition(.scale)
                        .animation(.easeInOut(duration: 1), value: viewModel.transactionStatusLabel)
                    Text(viewModel.amountDisplay)
                        .font(.plexSans(size: 40, weight: .medium))
                        .dynamicTypeSize(.small ... .xxLarge)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .modifier(RadialGradientForegroundStyleModifier())
                    
                    Text(viewModel.ticker)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                transactionDetailsSection()
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 14)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: -0.5)
                    .stroke(.grey4.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 18)
            .padding(.top, 20)
            
            Spacer()
            
            RoundedButton(action: {
                if viewModel.isLoading {
                    viewModel.dismiss()
                }
                navigationManager.reset()
            }, title: "close".localized)
            .padding(.bottom, 20)
            .padding(.horizontal, 18)
        }
        .modifier(AppBackgroundModifier())
        .onAppear {
            if !hasStartedTransaction {
                hasStartedTransaction = true
                Task {
                    await viewModel.callTransaction()
                }
            }
        }
    }
    
    private func transactionDetailsSection() -> some View {
        Group {
            VStack(spacing: 30) {
                Divider()
                    .background(.white.opacity(0.1))
                    .transition(.opacity)
                
                Button {
                    if let transaction = viewModel.getTransactionViewModel() {
                        navigationManager.navigate(to: .transactionDetails(transaction: TransactionDetailViewModel(transaction: transaction)))
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("accountDetails.title".localized)
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                        Image("ico_back")
                            .rotationEffect(.degrees(180))
                    }
                }
                .transition(.opacity)
            }
            .opacity(!viewModel.isLoading ? 1 : 0)
            .transition(.opacity)
            .animation(.easeInOut(duration: 1), value: !viewModel.isLoading)
        }
    }
    
    private func setupBinding() {
        Publishers.CombineLatest(
            viewModel.$transferDataType,
            viewModel.$error
        )
        .map { transferDataType, error in
            return transferDataType != nil && error == nil
        }
        .receive(on: RunLoop.main)
        .sink { newValue in
            self.isTransactionDetailsVisible = newValue
        }
        .store(in: &cancellables)
    }
}
