//
//  CompleteSetupPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 30.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct CompleteSetupPopup: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            PopupContainer(icon: "unlock_icon",
                           title: "unlock.feature".localized,
                           subtitle: "unlock.feature.subtitle".localized,
                           content: goBackButton()) {
                isVisible = false
            }
        }
    }
    
    private  func goBackButton() -> some View {
        Button {
            isVisible = false
        } label: {
            Text("go.back".localized)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                .cornerRadius(21)
        }
    }
}
