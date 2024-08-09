//
//  WelcomeView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @State var isChecked: Bool = false
    @SwiftUI.Environment(\.openURL) var openURL
    
    var action: () -> Void
    
    var body: some View {
        ZStack {
            Image("welcome_background").resizable().aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            
            VStack(alignment: .leading) {
                Spacer()
                VStack {
                    Text("new_onboarding_welcome_title".localized)
                        .multilineTextAlignment(.leading)
                        .font(.satoshi(size: 32, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint1)
                        .frame(alignment: .leading)
                }
                .padding(24)
                
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        Image("welcome_safe_secure_icon")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("new_onboarding_safe_secure_title".localized)
                                .font(.satoshi(size: 16, weight: .medium))
                                .foregroundStyle(Color.Neutral.tint1)
                                .frame(alignment: .leading)
                                
                            Text("new_onboarding_safe_secure_subtitle".localized)
                                .multilineTextAlignment(.leading)
                                .font(.satoshi(size: 14, weight: .regular))
                                .foregroundStyle(Color.Neutral.tint2)
                        }
                    }
                    HStack(spacing: 12) {
                        Image("welcome_manage_assets_icon")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("new_onboarding_manage_asssets_title".localized)
                                .font(.satoshi(size: 16, weight: .medium))
                                .foregroundStyle(Color.Neutral.tint1)
                                .frame(alignment: .leading)
                                
                            Text("new_onboarding_manage_asssets_subtitle".localized)
                                .multilineTextAlignment(.leading)
                                .font(.satoshi(size: 14, weight: .regular))
                                .foregroundStyle(Color.Neutral.tint2)
                        }
                    }
                    HStack(spacing: 12) {
                        Image("welcome_unlimited_pos_icon")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("new_onboarding_unlimited_possibilities_title".localized)
                                .font(.satoshi(size: 16, weight: .medium))
                                .foregroundStyle(Color.Neutral.tint1)
                                .frame(alignment: .leading)
                                
                            Text("new_onboarding_unlimited_possibilities_subtitle".localized)
                                .multilineTextAlignment(.leading)
                                .font(.satoshi(size: 14, weight: .regular))
                                .foregroundStyle(Color.Neutral.tint2)
                        }
                    }
                }
                .padding(.leading, 38)
                .padding(.trailing, 24)
                
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Image(isChecked ? "checkbox_checked" : "checkbox_unchecked")
                            .contentShape(.rect)
                            .onTapGesture {
                                isChecked.toggle()
                                Tracker.trackContentInteraction(name: "Welcome screen", interaction: .checked, piece: "Check box")
                            }
                        
                        ///
                        /// I would love to move this string literals out to constants, but in that case markdown stop working, and treat this string as `string` instead of `markdown`
                        ///
                        Group {
                            Text("new_onb_privacy_read".localized)
                            + Text(" ")
                            + Text("[\("new_onb_terms".localized)](https://developer.concordium.software/en/mainnet/net/resources/terms-and-conditions-cryptox.html)").underline()
                            + Text(" ")
                            + Text("and".localized)
                            + Text(" ")
                            + Text("[\("new_onb_privacy".localized)](https://www.concordium.com/privacy-policy)").underline()
                        }
                        .accentColor(Color.Neutral.tint1)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint1)
                        
                        Spacer(minLength: 1)
                    }
                    .padding(.horizontal, 16)
                    
                    Button(
                        action: {
                        action()
                            Tracker.trackContentInteraction(name: "Welcome screen", interaction: .clicked, piece: "Get started")
                    }, label: {
                        HStack {
                            Text("get_started_btn_title".localized)
                                .font(Font.satoshi(size: 16, weight: .medium))
                                .lineSpacing(24)
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                        .padding(.horizontal, 24)
                    })
                    .opacity(isChecked ? 1.0 : 0.7)
                    .disabled(!isChecked)
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 64)
            }
        }
    }
}

#Preview {
    WelcomeView() {}
}

