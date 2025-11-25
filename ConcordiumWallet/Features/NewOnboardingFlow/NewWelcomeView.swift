//
//  NewWelcomeView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 31.10.2025.
//  Copyright © 2025 Concordium. All rights reserved.
//

import SwiftUI

struct NewWelcomeView: View {

    @State var isChecked: Bool = false
    @AppStorage("isAcceptedPrivacy") private var isAcceptedPrivacy = false
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack(spacing: 16) {
            Image("launch_icon")
                .resizable()
                .frame(width: 64, height: 64)
            
            Text("smart.money.title".localized)
                .font(.satoshi(size: 24, weight: .medium))
                .foregroundStyle(.semanticContentPrimary)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 24) {
                ForEach(1..<4) { item in
                    stepItem(num: item)
                }
            }
            .frame(alignment: .leading)
            Spacer()
            
            termsAndConditionsItem
            
            RoundedButton(action: {
                navigationManager.navigate(to: .createNewWallet)
            }, title: "create_wallet_sheet".localized, isDisabled: !isChecked)
            
            RoundedButton(action: {
                navigationManager.navigate(to: .restoreExistingWallet)
            }, title: "restore.wallet".localized, foregroundColor: .white, backgroundColor: .semanticSurfaceSecondary, isDisabled: !isChecked)
            
        }
        .padding(.top, 52)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    private func numberView(num: Int) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("\(num)")
                .font(.satoshi(size: 16, weight: .medium))
              .multilineTextAlignment(.center)
              .foregroundColor(.semanticContentPrimary)
        }
        .frame(width: 32, height: 32, alignment: .center)
        .background(.surfaceTertiary)
        .cornerRadius(9999)
    }
    
    private func stepItem(num: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            numberView(num: num)
            VStack(alignment: .leading, spacing: 11) {
                Text("onb.item.\(num).title".localized)
                    .font(.satoshi(size: 16, weight: .bold))
                    .foregroundStyle(Color.Neutral.tint1)
                    .frame(alignment: .leading)
                
                Text("onb.item.\(num).desc".localized)
                    .multilineTextAlignment(.leading)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(.accentSecondary)
            }
            .padding(.top, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var termsAndConditionsItem: some View {
        HStack(spacing: 16) {
            Image(isChecked ? "checkbox_checked" : "checkbox_unchecked")
                .contentShape(.rect)
                .onTapGesture {
                    isChecked.toggle()
                }

            Group {
                Text("new_onb_privacy_read".localized)
                + Text(" ")
                + Text("[\("new_onb_terms".localized)](https://developer.concordium.software/en/mainnet/net/resources/terms-and-conditions-cryptox.html)").underline()
                + Text(" ")
                + Text("and".localized)
                + Text(" ")
                + Text("[\("new_onb_privacy".localized)](https://www.concordium.com/legal/privacy-policy)").underline()
            }
            .font(.satoshi(size: 14, weight: .regular))
            .foregroundStyle(.semanticContentPrimary)
            .accentColor(.semanticContentPrimary)
            
            Spacer(minLength: 1)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    NewWelcomeView()
}
