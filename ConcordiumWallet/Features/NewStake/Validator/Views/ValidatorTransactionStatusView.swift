//
//  ValidatorTransactionStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Lottie
import Combine

struct ValidatorTransactionStatusView: View {
    private enum AnimationState { case loader, success, failure }

    @State private var animationState: AnimationState = .loader
    @State private var currentSegment: ClosedRange<Int>? = 0...120
    @State private var loopMode: LottieLoopMode = .loop
    @State private var playToken: Int = 0

    @State private var hasStartedTransaction = false
    @State private var isTransactionDetailsVisible: Bool = true
    @State private var cancellables = Set<AnyCancellable>()

    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var viewModel: ValidatorSubmissionViewModel

    private let animationFile = "loadingAnimation"

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 30) {
                animationView()
                    .id(animationState)
                    .frame(width: 60, height: 60)

                Divider()
                VStack(spacing: 8) {
                    Text(viewModel.transactionStatusLabel)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .transition(.scale)
                        .animation(.easeInOut(duration: 1), value: viewModel.transactionStatusLabel)
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
                viewModel.closeTapped {
                    navigationManager.reset()
                }
            }, title: "close".localized)
            .padding(.bottom, 20)
            .padding(.horizontal, 18)
            .opacity(viewModel.isTransactionExecuting ? 0 : 1)
        }
        .modifier(AppBackgroundModifier())
        .modifier(AlertModifier(alertOptions: viewModel.alertOptions, isPresenting: $viewModel.showAlert))
        .onAppear {
            playAnimationBasedOnState()
            if !hasStartedTransaction {
                hasStartedTransaction = true
                viewModel.pressedButton()
            }
        }
        .onChange(of: viewModel.isTransactionExecuting) { _ in
            playAnimationBasedOnState()
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
                            .font(.satoshi(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                        Image("ico_back")
                            .rotationEffect(.degrees(180))
                    }
                }
                .transition(.opacity)
            }
            .opacity(!viewModel.isTransactionExecuting ? 1 : 0)
            .transition(.opacity)
            .animation(.easeInOut(duration: 1), value: !viewModel.isTransactionExecuting)
        }
    }

    @ViewBuilder
    private func animationView() -> some View {
        LottiePlayer(name: animationFile,
                     segment: currentSegment,
                     loopMode: loopMode,
                     playToken: playToken)
    }

    private func playAnimationBasedOnState() {
        switch (viewModel.isTransactionExecuting, viewModel.error != nil) {
        case (true, _):
            animationState = .loader
            currentSegment = 0...120
            loopMode = .loop
        case (false, true):
            animationState = .failure
            currentSegment = 300...360
            loopMode = .playOnce
        default:
            animationState = .success
            currentSegment = 121...239
            loopMode = .playOnce
        }
        playToken += 1
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
