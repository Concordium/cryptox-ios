//
//  AccountPreviewCardView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 24.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountPreviewCardView: View {
    @State private var progress: Float?
    @State private var targetProgress: Float = 0
    @State private var title: String = ""
    @State private var stepName: String = ""
    @State private var isDotPulsating = false
    @State private var checkmarkOpacity: Double = 0.0
    @State private var isTransitioning = false
    @Binding var isCreatingAccount: Bool

    var onCreateAccount: (() -> Void)? = nil
    var onIdentityVerification: (() -> Void)? = nil
    var state: AccountsMainViewState = .empty
    var viewModel: AccountPreviewViewModel?
    var onQrTap: (() -> Void)?
    var onSendTap: (() -> Void)?
    var onShowPlusTap: (() -> Void)?

    private var isAccountState: Bool {
        state == .accounts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            setupView()
                .padding(16)
                .frame(height: 132)
        }
        .cornerRadius(16)
        .background(.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.75)
                .stroke(Color(red: 0.53, green: 0.53, blue: 0.53), lineWidth: 1.5)
            
        )
        .onAppear {
            stateChange()
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = targetProgress
            }
        }
    }

    @ViewBuilder
    private func setupView() -> some View {
        VStack(alignment: .leading) {
            switch state {
            case .saveSeedPhrase, .createIdentity, .identityVerification:
                verificationProgressView
            case .createAccount:
                createAccountView
            case .verificationFailed:
                verificationFailedView
            default:
                EmptyView()
            }
        }
    }

    private var verificationProgressView: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(state == .identityVerification ? .yellowMain : .greyMain)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                if state == .identityVerification {
                    Circle()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(.yellowMain)
                        .opacity(isDotPulsating ? 0.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isDotPulsating)
                        .onAppear { isDotPulsating = true }
                }
            }
            
            ProgressView(value: progress)
                .frame(height: isTransitioning ? 56 : 11)
                .progressViewStyle(CustomProgressViewStyle(trackColor: Color(red: 0.09, green: 0.1, blue: 0.1)))
                .cornerRadius(5)
                .onChange(of: targetProgress) { newValue in
                    withAnimation(.easeInOut(duration: 1.0)) {
                        progress = newValue
                    }
                }
            
            Text(stepName)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(Color.greyMain)
                .padding(.bottom, 8)
        }
    }

    private var createAccountView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(isCreatingAccount ? "finalizing_account".localized : title)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(Color.greenMain)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                if isCreatingAccount {
                    Circle()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(.greenMain)
                        .opacity(isDotPulsating ? 0.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isDotPulsating)
                        .onAppear { isDotPulsating = true }
                } else {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.greenMain)
                        .opacity(checkmarkOpacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.5)) {
                                checkmarkOpacity = 1.0
                            }
                        }
                }
            }
            Button(action: {
                onCreateAccount?()
                Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Create Account")
            }) {
                buttonLabel("create_account_btn_title".localized)
            }
            .background(isCreatingAccount ? .blackMain : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .inset(by: 0.5)
                    .stroke(Color(red: 0.44, green: 0.47, blue: 0.49), lineWidth: isCreatingAccount ? 1 : 0)
            )
            .disabled(isCreatingAccount)
            .opacity(isCreatingAccount ? 0.5 : 1.0)
            .clipShape(Capsule())
            .padding(.bottom, 22)
        }
    }

    private var verificationFailedView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(Color.Status.attentionRed)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                Image(systemName: "xmark")
                    .foregroundStyle(Color.Status.attentionRed)
            }
            Button(action: {
                onIdentityVerification?()
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Verify failed identity")
            }) {
                buttonLabel("create_wallet_step_3_title".localized)
            }
            .background(Color.EggShell.tint1)
            .clipShape(Capsule())
            .padding(.bottom, 22)
        }
    }

    private func buttonLabel(_ text: String) -> some View {
        Text(text)
            .font(Font.satoshi(size: 15, weight: .medium))
            .foregroundColor(isCreatingAccount ? .grey4 : .blackMain)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isCreatingAccount ? .blackMain : .white)
            .cornerRadius(28)
        
    }

    private func stateChange() {
        switch state {
        case .createAccount:
            progress = 1
            targetProgress = 1
            title = "verification.completed".localized
        case .createIdentity:
            stepName = "final_step_verify_identity".localized
            progress = 1 / 3
            targetProgress = 2 / 3
            title = "setup_progress_title".localized
            Tracker.track(view: ["Onboarding: Create Identity step"])
        case .identityVerification:
            progress = 2 / 3
            targetProgress = 1
            stepName = "setup.complete".localized
            title = "verification.in.progress".localized
            Tracker.track(view: ["Onboarding: Identity verification step"])
        case .verificationFailed:
            title = "verification.failed".localized
            Tracker.track(view: ["Onboarding: Verification failed step"])
        case .saveSeedPhrase:
            stepName = "next_step_seed_phrase".localized
            progress = 0
            targetProgress = 1 / 3
            title = "setup_progress_title".localized
            Tracker.track(view: ["Onboarding: Save seed phrase step"])
        default:
            break
        }
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    var trackColor: Color
    var gradientColors: [Color] {
        return [Color(red: 0.62, green: 0.95, blue: 0.92),
                Color(red: 0.93, green: 0.85, blue: 0.75),
                Color(red: 0.64, green: 0.6, blue: 0.89)]
    }
    
    @State private var gradientOffset: CGFloat = 0.0
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                trackColor
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(5)
                
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .init(x: gradientOffset, y: 0),
                    endPoint: .init(x: gradientOffset + 1, y: 0)
                )
                .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: geometry.size.height)
                .cornerRadius(5)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 3.0).repeatForever(autoreverses: true)
                    ) {
                        gradientOffset = 1.0
                    }
                }
            }
        }
    }
}
