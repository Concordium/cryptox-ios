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
        case recoverWithWalletKey
    }
    
    @State private var flow: Flow? = nil
    @State private var recoveryPhrase: RecoveryPhrase? = nil
    @State private var isLegacyImportInfoShown: Bool = false
    @State private var isInfoViewPresented = false
    
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
                    
                    optionsView()
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
    func optionsView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image("Frame 1984")
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Seed phrase wallet")
                    .font(.satoshi(size: 20, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                Text("import_wallet_recover_phrase_subtitle".localized)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.Neutral.tint2)
                    .opacity(0.5)
            }
            
            Divider()
                .tint(Color("black_secondary"))
            
            HStack {
                Text("Import via seed phrase")
                    .font(.satoshi(size: 14, weight: .regular))
                Spacer()
                Image(systemName: "arrow.right").tint(Color.Neutral.tint1)
            }
            .onTapGesture {
                self.flow = .recoverPhraseInput
            }
            
            Divider()
                .tint(Color("black_secondary"))
            
            HStack {
                Text("Import via exported file")
                    .font(.satoshi(size: 14, weight: .regular))
                Spacer()
                Image(systemName: "arrow.right").tint(Color.Neutral.tint1)
            }
            .onTapGesture {
                isLegacyImportInfoShown.toggle()
            }
            
            Divider()
                .tint(Color("black_secondary"))
            
            HStack {
                Text("Import via wallet private key")
                    .font(.satoshi(size: 14, weight: .regular))
                Spacer()
                Image(systemName: "arrow.right").tint(Color.Neutral.tint1)
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
        .overlay(
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "info.circle")
                        .padding(16)
                        .onTapGesture {
                            isInfoViewPresented = true
                        }
                    Spacer()
                }
            }
        )
        .contentShape(.rect)
        .sheet(isPresented: $isInfoViewPresented) {
            ImportWalletInfoView()
        }
    }
}
