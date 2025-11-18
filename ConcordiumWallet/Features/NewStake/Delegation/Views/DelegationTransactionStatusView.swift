//
//  DelegationTransactionStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct DelegationTransactionStatusView: View {

    // MARK: Other View state
    @State private var hasStartedTransaction = false
    @State private var cancellables = Set<AnyCancellable>()
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var viewModel: DelegationSubmissionViewModel


    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 30) {
                LottieLoadingAnimation(isTransactionExecuting: $viewModel.isTransactionExecuting, error: $viewModel.error)
                Divider()
                statusSection()
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
                viewModel.closeTapped { navigationManager.reset() }
            }, title: "close".localized)
            .padding(.bottom, 20)
            .padding(.horizontal, 18)
            .opacity(viewModel.isTransactionExecuting ? 0 : 1)
        }
        .modifier(AppBackgroundModifier())
        .modifier(AlertModifier(alertOptions: viewModel.alertOptions, isPresenting: $viewModel.showAlert))
        .onAppear {
            guard !hasStartedTransaction else { return }
            hasStartedTransaction = true
            viewModel.pressedButton()
        }
    }

    @ViewBuilder private func statusSection() -> some View {
        VStack(spacing: 8) {
            Text(viewModel.transactionStatusLabel)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .transition(.scale)
                .animation(.easeInOut(duration: 1),
                           value: viewModel.transactionStatusLabel)

            if viewModel.shouldDisplayAmount {
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
        }
    }

    @ViewBuilder private func transactionDetailsSection() -> some View {
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
                            .font(.satoshi(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                        Image("ico_back")
                            .rotationEffect(.degrees(180))
                    }
                }
                .transition(.opacity)
            }
            .opacity(viewModel.isTransactionExecuting ? 0 : 1)
            .animation(.easeInOut(duration: 1),
                       value: viewModel.isTransactionExecuting)
        }
        .opacity(viewModel.getTransactionViewModel() != nil ? 1 : 0)
    }
}
