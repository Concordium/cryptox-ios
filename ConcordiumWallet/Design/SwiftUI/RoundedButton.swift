//
//  RoundedButton.swift
//  CryptoX
//
//  Created by Zhanna Komar on 07.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct RoundedButton: View {
    let action: () -> Void
    let title: String
    var foregroundColor: Color = .blackMain
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .font(Font.satoshi(size: 15, weight: .medium))
                .foregroundColor(foregroundColor)
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
