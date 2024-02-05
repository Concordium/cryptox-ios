//
//  ImportLegacyWalletInfo.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 23.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ImportLegacyWalletInfo: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("recover_wallet_export_title".localized)
                            .font(.satoshi(size: 20, weight: .medium))
                            .foregroundStyle(Color.Neutral.tint1)
                        Text("recover_wallet_export_body".localized)
                            .font(.satoshi(size: 14, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint2)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.Neutral.tint6)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
                )
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .modifier(AppBackgroundModifier())
            .navigationTitle("recoveryphrase.recover.intro.navigationtitle".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }, label: {
                        Image(systemName: "xmark")
                            .font(.callout)
                            .frame(width: 35, height: 35)
                            .foregroundStyle(Color.primary)
                            .background(.ultraThinMaterial, in: .circle)
                            .contentShape(.circle)
                    })
                    
                }
            }
        }
    }
}

#Preview {
    ImportLegacyWalletInfo()
}
