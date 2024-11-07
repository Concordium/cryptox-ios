//
//  AccountPreviewCardView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 24.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountPreviewCardView: View {
    @State private var progress: Float = 0
    @State private var targetProgress: Float = 0
    @State private var title: String = ""
    @State private var stepName: String = ""
    @State private var isDotPulsating = false
    @State private var checkmarkOpacity: Double = 0.0
    @State private var isTransitioning = false

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

    private var backgroundGradient: some View {
        Group {
            if isAccountState {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.92, green: 0.98, blue: 0.91), Color(red: 0.77, green: 0.84, blue: 0.89)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color.clear
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .leading) {
                backgroundGradient
                Image(isAccountState ? "card_bg_gradient" : "card_bg")
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 14) {
                    setupView()
                        .padding(16)

                }
            }
            buttonSection
                .background(isAccountState ? Color.Neutral.tint5 : .clear)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(isAccountState ? Color.Neutral.tint1.opacity(0.05) : .blackAditional, lineWidth: 1.5)
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
            case .accounts:
                if let viewModel {
                    AccountInfoView(viewModel: viewModel)
                }
            default:
                EmptyView()
            }
        }
    }

    private var verificationProgressView: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: state == .identityVerification ? 16 : 14, weight: .medium))
                    .foregroundStyle(state == .identityVerification ? .yellowMain : .greyMain)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
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
                .progressViewStyle(CustomProgressViewStyle(trackColor: .greenDark, progressColor: .greenMain))
                .cornerRadius(5)
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Text(stepName)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(Color.greyMain)
                .padding(.bottom, 8)
        }
    }

    private var createAccountView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 16, weight: .medium))
                    .foregroundStyle(Color.greenMain)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.greenMain)
                    .opacity(checkmarkOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.5)) {
                            checkmarkOpacity = 1.0
                        }
                    }
            }
            Button(action: {
                onCreateAccount?()
                Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Create Account")
            }) {
                buttonLabel("create_account_btn_title".localized)
            }
            .background(.greenSecondary)
            .clipShape(Capsule())
            .padding(.bottom, 22)
        }
    }

    private var verificationFailedView: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 16, weight: .medium))
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

    private var buttonSection: some View {
        HStack(alignment: .center) {
            Spacer()
            controlButton(imageName: "ico_plus", action: onShowPlusTap)
            Spacer()
            dividerLine
            Spacer()
            controlButton(imageName: "ico_share", action: onSendTap)
            Spacer()
            dividerLine
            Spacer()
            controlButton(imageName: "ico_qr", action: onQrTap)
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundColor(.blackAditional)
                .frame(maxHeight: .infinity, alignment: .top),
            alignment: .top
        )
    }

    private func controlButton(imageName: String, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Image(imageName)
                .foregroundStyle(isAccountState ? Color.Neutral.tint1 : .blackAditional)
        }
        .disabled(!isAccountState)
        .frame(width: 40, height: 40)
    }

    private var dividerLine: some View {
        Rectangle()
            .frame(width: 1.0)
            .foregroundColor(isAccountState ? Color.Neutral.tint1.opacity(0.05) : .blackAditional)
            .padding(.vertical, -7)
    }

    private func buttonLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.blackMain)
                .font(.satoshi(size: 16, weight: .medium))
                .padding(.vertical, 16)
            Spacer()
            Image(systemName: "arrow.right")
                .tint(.blackMain)
        }
        .padding(.horizontal, 24)
    }

    private func stateChange() {
        switch state {
        case .createAccount:
            title = "verification.completed".localized
        case .createIdentity:
            stepName = "final_step_verify_identity".localized
            targetProgress = 2 / 3
            title = "setup_progress_title".localized
            Tracker.track(view: ["Onboarding: Create Identity step"])
        case .identityVerification:
            targetProgress = 1
            stepName = "setup.complete".localized
            title = "verification.in.progress".localized
            Tracker.track(view: ["Onboarding: Identity verification step"])
        case .verificationFailed:
            title = "verification.failed".localized
            Tracker.track(view: ["Onboarding: Verification failed step"])
        case .saveSeedPhrase:
            stepName = "next_step_seed_phrase".localized
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
    var progressColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                trackColor
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(5)
                
                progressColor
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: geometry.size.height)
                    .cornerRadius(5)
            }
        }
    }
}


#Preview {
    AccountPreviewCardView(state: .accounts)
        .frame(height: 188)
}
