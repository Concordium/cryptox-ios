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
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Text("Hiding a token")
                .font(.satoshi(size: 16, weight: .semibold))
                .foregroundStyle(.grey1)
            Text("Are you sure you want to hide \(tokenName) token from your wallet?")
                .font(.satoshi(size: 15, weight: .regular))
                .foregroundStyle(.grey1)
            VStack(spacing: 16) {
                Button {
                    onHideToken()
                    isPresentingAlert = false
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
                    .foregroundStyle(.blackMain)
                    .onTapGesture {
                        isPresentingAlert = false
                    }
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .frame(width: 327, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 40)
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
        .cornerRadius(16)
    }
}
