//
//  DismissBackupPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.11.2025.
//  Copyright © 2025 Concordium. All rights reserved.
//

import SwiftUI

struct DismissBackupPopup: View {
    
    @Binding var isPresentingAlert: Bool
    var onBackupTapped: () -> Void
    var onHideTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Text("dismiss.backup.popup.title".localized)
                .font(.satoshi(size: 20, weight: .medium))
                .foregroundStyle(Color.Neutral.tint7)
                .multilineTextAlignment(.center)
            Text("dismiss.backup.popup.desc".localized)
                .font(.satoshi(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.grey1)
            VStack(spacing: 8) {
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onBackupTapped()
                        withAnimation {
                            isPresentingAlert = false
                        }
                    }
                } label: {
                    Text("Back Your Seed phrase")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
                .background(.blackMain)
                .cornerRadius(9999)

                Button {
                    onHideTapped()
                    withAnimation {
                        isPresentingAlert = false
                    }
                } label: {
                    Text("Hide anyway")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(12)
                }
            }
        }
        .padding(32)
        .frame(width: 327, alignment: .top)
        .modifier(FloatingGradientBGStyleModifier())
        .cornerRadius(16)
    }
}
