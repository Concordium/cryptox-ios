//
//  ImportWalletView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 09.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ImportWalletView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var sanityChecker: SanityChecker
    
    let defaultProvider: ServicesProvider
    var onAccountInported: () -> Void
    
    enum Flow {
        case recoverPhraseInput
    }
    
    @State private var flow: Flow? = nil
    @State private var recoveryPhrase: RecoveryPhrase? = nil
    @State private var isLegacyImportInfoShown: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("import_wallet_flow_title")
                        .font(.satoshi(size: 24, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint1)
                    Text("import_wallet_flow_subtitle".localized)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint2)
                }
                .padding(.top, 64)
                
                VStack(spacing: 8) {
                    NavigationLink(
                        destination: ImportWalletSeedPhraseView(viewModel: ImportWalletSeedPhraseViewModel.init(recoveryService: defaultProvider.recoveryPhraseService(), onValidPhrase: { phrase in
                            self.recoveryPhrase = phrase
                        })),
                        tag: Flow.recoverPhraseInput,
                        selection: $flow) { EmptyView() }
                    
                    Card(title: "import_wallet_recover_phrase_title".localized, subtitle: "import_wallet_recover_phrase_subtitle".localized, image: "Frame 1984")
                        .contentShape(.rect)
                        .onTapGesture {
                            self.flow = .recoverPhraseInput
                        }
                    
                    Card(title: "import_wallet_export_phrase_title".localized, subtitle: "import_wallet_export_phrase_subtitle".localized, image: "Frame 1985")
                        .contentShape(.rect)
                        .onTapGesture {
                            isLegacyImportInfoShown.toggle()
                        }
                }
                
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
            .fullScreenCover(item: $recoveryPhrase) { phrase in
                RecoverAccountsView(viewModel: .init(phrase: phrase, defaultProvider: defaultProvider, onAccountInported: onAccountInported))
            }
            .fullScreenCover(isPresented: $isLegacyImportInfoShown) {
                ImportLegacyWalletInfo()
            }
        }
    }
    
    @ViewBuilder
    func Card(title: String, subtitle: String, image: String) -> some View {
        VStack(spacing: 16) {
            Image(image)
            VStack(spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 20, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                Text(subtitle)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.Neutral.tint2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.Neutral.tint6)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
        .contentShape(.rect)
    }
}
