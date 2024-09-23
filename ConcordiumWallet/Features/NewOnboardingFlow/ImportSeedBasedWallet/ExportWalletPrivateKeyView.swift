//
//  ExportWalletPrivateKeyView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 20.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

import SwiftUI
import MnemonicSwift

final class ExportWalletPrivateKeyViewModel: ObservableObject {
    @Published var walletPrivateKey = ""
    
    private let dependencyProvider: ServicesProvider

    init(dependencyProvider: ServicesProvider) {
        self.dependencyProvider = dependencyProvider
    }

    func getPrivateKey(pwHash: String) {
        Task {
            do {
                let recoveryPhrase = try dependencyProvider.keychainWrapper().getValue(for: "RecoveryPhrase", securedByPassword: pwHash).get()
                let seedValue = recoveryPhrase.data(using: .utf8)?.hexDescription
                await MainActor.run {
                    withAnimation {
                        self.walletPrivateKey = seedValue ?? ""
                    }
                }
            } catch {
                self.walletPrivateKey = ""
                debugPrint(error)
            }
        }
    }
}

struct ExportWalletPrivateKeyView: View {
    @ObservedObject var viewModel: ExportWalletPrivateKeyViewModel
    
    @SwiftUI.Environment(\.dismiss) var dismiss

    @State var shareText: ShareText?
    @State var isShowPasscodeViewShown: Bool = false
    
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("wallet_private_key_title".localized)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                Text("wallet_private_key_subtitle".localized)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 64)
            
            HStack {
                HStack(spacing: 4) {
                    Image("seed_green_check")
                    Text("copy_and_keep_safe".localized)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint1)
                }
                HStack(spacing: 4) {
                    Image("seed_red_check")
                    Text("digital_copy".localized)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint1)
                }
                HStack(spacing: 4) {
                    Image("seed_red_check")
                    Text("screenshot".localized)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint1)
                }
            }
            
            if viewModel.walletPrivateKey.isEmpty {
                Image("wallet_privateKey_locked")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .containerShape(.rect)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        isShowPasscodeViewShown.toggle()
                    }
                    .matchedGeometryEffect(id: "LockTransition", in: animation)
            } else {
                PrivateKeyView()
                    .matchedGeometryEffect(id: "LockTransition", in: animation)
            }
            
            Button {
                if viewModel.walletPrivateKey.isEmpty {
                    isShowPasscodeViewShown.toggle()
                } else {
                    shareText = ShareText(text: viewModel.walletPrivateKey)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.walletPrivateKey.isEmpty ? "show_wallet_private_key".localized : "copy.to.clipoard".localized)
                        .foregroundStyle(Color.Neutral.tint1)
                        .font(.satoshi(size: 14, weight: .medium))
                    Image(viewModel.walletPrivateKey.isEmpty ? "seed_phrase_reveal" : "seed_phrase_copy")
                }
            }
            .padding(.top, 22)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .modifier(AppBackgroundModifier())
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(.callout)
                    .frame(width: 35, height: 35)
                    .foregroundStyle(Color.primary)
                    .background(.ultraThinMaterial, in: .circle)
                    .contentShape(.circle)
            })
            .padding(.top, 12)
            .padding(.trailing, 15)
        }
        .sheet(item: $shareText) { shareText in
            ActivityView(text: shareText.text)
        }
        .passcodeInput(isPresented: $isShowPasscodeViewShown) { pwHash in
            viewModel.getPrivateKey(pwHash: pwHash)
        }
    }
    
    @ViewBuilder
    func PrivateKeyView() -> some View {
        VStack(alignment: .center) {
            Text(viewModel.walletPrivateKey)
                .font(.satoshi(size: 14, weight: .medium))
                .padding(12)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
                )
        }
        .frame(minHeight: 10)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.textBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
    }
}


#Preview {
    ExportWalletPrivateKeyView(viewModel: ExportWalletPrivateKeyViewModel(dependencyProvider: ServicesProvider.defaultProvider()))
}
