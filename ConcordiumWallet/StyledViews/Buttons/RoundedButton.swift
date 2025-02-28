//
//  RoundedButton.swift
//  CryptoX
//
//  Created by Zhanna Komar on 18.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct RoundedButton: View {
    let action: () -> Void
    let title: String
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .font(Font.satoshi(size: 15, weight: .medium))
                .foregroundColor(.blackMain)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .cornerRadius(28)
        })
        .buttonStyle(PressedButtonStyle())
    }
}

#Preview {
    RoundedButton(action: {}, title: "Continue")
}
