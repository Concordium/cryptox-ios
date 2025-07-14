//
//  DelegationTransactionStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Lottie
import Combine

struct DelegationTransactionStatusView: View {

    private enum AnimationState { case loader, success, failure }

    @State private var animationState: AnimationState = .loader
    @State private var currentSegment: ClosedRange<Int>? = 0...120
    @State private var loopMode: LottieLoopMode = .loop
    /// Increment this to force `LottiePlayer` to restart with same segment
    @State private var playToken = 0

    // MARK: Other View state
    @State private var hasStartedTransaction = false
    @State private var cancellables = Set<AnyCancellable>()
    @EnvironmentObject var navigationManager: NavigationManager
    @ObservedObject var viewModel: DelegationSubmissionViewModel

    private let animationFile = "loadingAnimation"

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 30) {
                LottiePlayer(name: animationFile,
                             segment: currentSegment,
                             loopMode: loopMode,
                             playToken: playToken)
                    .id(animationState)
                    .frame(width: 60, height: 60)
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
            playAnimationBasedOnState()
            guard !hasStartedTransaction else { return }
            hasStartedTransaction = true
            viewModel.pressedButton()
        }
        .onChange(of: viewModel.isTransactionExecuting) { _ in
            playAnimationBasedOnState()
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
    }

    private func playAnimationBasedOnState() {
        switch (viewModel.isTransactionExecuting, viewModel.error != nil) {
        case (true, _):
            animationState       = .loader
            currentSegment       = 0...120
            loopMode             = .loop
        case (false, true):
            animationState       = .failure
            currentSegment       = 300...360
            loopMode             = .playOnce
        default:
            animationState       = .success
            currentSegment       = 121...239
            loopMode             = .playOnce
        }
        playToken += 1
    }
}
