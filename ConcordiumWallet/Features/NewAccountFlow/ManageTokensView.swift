//
//  ManageTokensView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ManageTokensView: View {
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AccountDetailViewModel2
    @State private var isPresentingAlert = false
    @State private var selectedToken: CIS2Token?
    @State var showRemovedTokenTip: Bool = false
    @State var showTokenListUpdated: Bool = false
    @Binding var path: [AccountNavigationPaths]
    @Binding var isNewTokenAdded: Bool

    var body: some View {
        ZStack {
            ScrollView {
                AccountTokenListView(
                    viewModel: viewModel,
                    showTokenDetails: .constant(false),
                    showManageTokenList: .constant(false),
                    selectedToken: .constant(nil),
                    mode: .manage,
                    onHideToken: { token in
                        withAnimation {
                            isPresentingAlert = true
                            selectedToken = token
                        }
                    }
                )
                .padding(.vertical, 20)
            }
            
            if isPresentingAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
                
                HideTokenPopup(
                    tokenName: selectedToken?.metadata.name ?? "",
                    isPresentingAlert: $isPresentingAlert
                ) {
                    if let selectedToken {
                        viewModel.removeToken(selectedToken)
                        showRemovedTokenTip = true
                    }
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
            }
            
            VStack {
                Spacer()
                if showRemovedTokenTip {
                    tokenListUpdatedTip(tokenRemoved: true, tokenName: selectedToken?.metadata.name ?? "")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 46)
                        .padding(.bottom, 16)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showRemovedTokenTip = false
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeInOut(duration: 0.3), value: showRemovedTokenTip)
                }
                
                if showTokenListUpdated {
                    tokenListUpdatedTip(tokenRemoved: false, tokenName: "")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 46)
                        .padding(.bottom, 16)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showTokenListUpdated = false
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .animation(.easeInOut(duration: 0.3), value: showTokenListUpdated)
                }
            }
        }
        .onChange(of: isNewTokenAdded) { _ in
            if isNewTokenAdded {
                showTokenListUpdated = true
                isNewTokenAdded = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(NavigationViewModifier(title: "Manage token list", backAction: {
            dismiss()
        }, trailingAction: {
            path.append(.addToken)
        }, trailingIcon: Image("ico_add")))
        .modifier(AppBackgroundModifier())
    }
    
    func tokenListUpdatedTip(tokenRemoved: Bool, tokenName: String) -> some View {
        VStack(alignment: .center) {
            HStack(spacing: 16) {
                Image(tokenRemoved ? "eyeSlash" : "ico_successfully")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.stone)
                    .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token list updated")
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.grey2)
                    if tokenRemoved {
                        Text("\(tokenName) hidden from your wallet")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.grey2)
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 43)
                .fill(
                    RadialGradient(gradient: Gradient(colors:
                                                        [Color(red: 0.62, green: 0.95, blue: 0.92),
                                                         Color(red: 0.93, green: 0.85, blue: 0.75),
                                                         Color(red: 0.64, green: 0.6, blue: 0.89)
                                                        ]),
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 400))
        )
    }
}
