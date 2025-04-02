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
    var foregroundColor: Color = .blackMain
    var isDisabled: Bool = false

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .font(Font.satoshi(size: 15, weight: .medium))
                .foregroundColor(isDisabled ? .grey4 : foregroundColor)
                .padding(.horizontal, 24)
                .padding(.vertical, isDisabled ? 18.5 : 0)
                .frame(maxWidth: .infinity)
                .cornerRadius(28)
        })
        .if(!isDisabled, transform: { view in
            view.buttonStyle(PressedButtonStyle())

        })
        .if(isDisabled, transform: { view in
            view.overlay(
                RoundedRectangle(cornerRadius: 48)
                    .inset(by: 0.5)
                    .stroke(.grey4, lineWidth: 1)
            )
        })
        .disabled(isDisabled)
    }
}

#Preview {
    RoundedButton(action: {}, title: "Continue", isDisabled: false)
}
