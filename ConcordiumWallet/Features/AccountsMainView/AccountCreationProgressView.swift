//
//  AccountCreationProgressView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 24.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountCreationProgressView: View {
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

    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Image("card_bg")
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 14) {
                    setupView()
                }
                .padding(.horizontal, 16)
            }
            HStack(alignment: .center) {
                Spacer()
                
                Image("ico_plus")
                    .frame(width: 40, height: 40)
                
                Spacer()
                
                Rectangle()
                    .frame(width: 1.0)
                    .foregroundColor(.blackAditional)
                    .padding(.vertical, -7)
                
                Spacer()
                
                Image("ico_share")
                    .renderingMode(.template)
                    .foregroundStyle(.blackAditional)
                    .frame(width: 40, height: 40)
                
                Spacer()
                
                Rectangle()
                    .frame(width: 1.0)
                    .foregroundColor(Color.blackAditional)
                    .padding(.vertical, -7)
                
                Spacer()
                
                Image("ico_qr")
                    .frame(width: 40, height: 40)
                
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color.blackAditional, lineWidth: 1.5)
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
                                .onAppear {
                                    isDotPulsating = true
                                }
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
                
            case .createAccount:
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
                    .padding(.top, 19)
                    
                    Button {
                        guard let onCreateAccount else { return }
                        onCreateAccount()
                    } label: {
                        HStack {
                            Text("create_account_btn_title".localized)
                                .foregroundColor(.blackMain)
                                .font(.satoshi(size: 16, weight: .medium))
                                .padding(.vertical, 16)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .tint(.blackMain)
                        }
                        .padding(.horizontal, 24)
                    }
                    .background(.greenSecondary)
                    .clipShape(Capsule())
                    .padding(.bottom, 22)
                    .transition(.scale.combined(with: .opacity))
                }
            case .verificationFailed:
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(title)
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundStyle(Color.Status.attentionRed)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.Status.attentionRed)
                }
                .padding(.top, 19)
                Button {
                    guard let onIdentityVerification else { return }
                    onIdentityVerification()
                } label: {
                    HStack {
                        Text("create_wallet_step_3_title".localized)
                            .foregroundColor(.blackMain)
                            .font(.satoshi(size: 16, weight: .medium))
                            .padding(.vertical, 16)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .tint(.blackMain)
                    }
                    .padding(.horizontal, 24)
                }
                .background(Color.EggShell.tint1)
                .clipShape(Capsule())
                .padding(.bottom, 22)
            default:
                EmptyView()
            }
        }
        .onChange(of: progress) { newValue in
            if state == .createAccount {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isTransitioning = true
                    }
                }
            }
        }
    }
    
    private func stateChange() {
        switch state {
        case .accounts, .empty:
            break
        case .createAccount:
            title = "verification.completed".localized
        case .createIdentity:
            stepName = "final_step_verify_identity".localized
            targetProgress = 2 / 3
            title = "setup_progress_title".localized
        case .identityVerification:
            targetProgress = 1
            stepName = "setup.complete".localized
            title = "verification.in.progress".localized
        case .verificationFailed:
            title = "verification.failed".localized
        case .saveSeedPhrase:
            stepName = "next_step_seed_phrase".localized
            targetProgress = 1 / 3
            title = "setup_progress_title".localized
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
    AccountCreationProgressView(state: .verificationFailed)
        .frame(height: 188)
}
