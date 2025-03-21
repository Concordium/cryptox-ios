//
//  HideTokenPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct HideTokenPopup: View {
    
    var tokenName: String
    @Binding var isPresentingAlert: Bool
    var onHideToken: () -> Void
    @State private var goBackTapped: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Text("Hiding a token")
                .font(.satoshi(size: 16, weight: .semibold))
                .foregroundStyle(.grey1)
            Text("Are you sure you want to hide \(tokenName) token from your wallet?")
                .font(.satoshi(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.grey1)
            VStack(spacing: 16) {
                Button {
                    onHideToken()
                    withAnimation {
                        isPresentingAlert = false
                    }
                } label: {
                    Text("Yes, hide it")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .background(.blackMain)
                .cornerRadius(21)
                Text("Go back")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(goBackTapped ? .grey4 : .blackMain)
                    .onTapGesture {
                        goBackTapped = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            goBackTapped = false
                            withAnimation {
                                isPresentingAlert = false
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .frame(width: 327, alignment: .top)
        .modifier(FloatingGradientBGStyleModifier())
        .cornerRadius(16)
    }
}
