//
//  MoreView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 17.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

final class MoreTabViewModel: ObservableObject {
    
}

struct MoreTab: View {
    let identitiesService: SeedIdentitiesService
    var onLogout: () -> Void
    
    @State var isRemoveAccountDialogShown: Bool = false
    @State var isShowSeedPhraseViewShown: Bool = false
    @State var hasSetupRecoveryPhrase: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    if hasSetupRecoveryPhrase {
                        MoreItem(title: "more.show.recovery.phrase.title".localized, subtitle: "more.show.recovery.phrase.subtitle".localized, icon: "eye") {
                            isShowSeedPhraseViewShown.toggle()
                        }
                    }
                    MoreItem(title: "more.deleteAccount".localized, subtitle: "more.deleteAccount.subtitle".localized, icon: "rectangle.portrait.and.arrow.right") {
                        isRemoveAccountDialogShown.toggle()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .modifier(AppBackgroundModifier())
            .navigationTitle("more_tab_title")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
        }
        .confirmationDialog("more.remove.account.confirmation.title".localized, isPresented: $isRemoveAccountDialogShown, titleVisibility: .visible) {
            Button("yes".localized, role: .destructive) {
                onLogout()
            }
        }
        .fullScreenCover(isPresented: $isShowSeedPhraseViewShown, content: {
            RevealSeedPhraseView(viewModel: .init(identitiesService: identitiesService))
        })
        .onAppear {
            hasSetupRecoveryPhrase = identitiesService.mobileWallet.isMnemonicPhraseSaved
        }
    }
    
     @ViewBuilder
    func MoreItem(title: String, subtitle: String, icon: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .imageScale(.large)
                .tint(Color.Neutral.tint1)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.satoshi(size: 16, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                    .frame(alignment: .leading)
                Text(subtitle)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint2)
                    .multilineTextAlignment(.leading)
                    .frame(alignment: .leading)
            }
            .padding(.trailing, 24)
            .frame(alignment: .leading)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Image(systemName: "arrow.right")
                .imageScale(.large)
                .tint(Color.Neutral.tint1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
            onTap()
        }
    }
}
