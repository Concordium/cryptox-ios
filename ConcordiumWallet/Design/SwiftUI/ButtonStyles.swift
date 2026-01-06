//
//  ButtonStyles.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 29/06/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct StandardStyle: ButtonStyle {
    let disabled: Bool
    let padding: CGFloat
    let fillWidth: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(padding)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .background(disabled ? Pallette.inactiveButton : Pallette.primary)
            .cornerRadius(10)
            .foregroundColor(configuration.isPressed ? .black.opacity(0.2) : .black)
            .font(Font(Fonts.buttonTitle))
    }
}

struct CapsuleStyle: ButtonStyle {
    let disabled: Bool
    let padding: CGFloat
    let fillWidth: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(padding)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .background(disabled ? Pallette.inactiveButton : Pallette.primary)
            .foregroundColor(configuration.isPressed ? .black.opacity(0.2) : .black)
            .font(Font(Fonts.buttonTitle))
            .clipShape(Capsule())
    }
}

struct DeclineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.satoshi(size: 14, weight: .medium))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(.semanticSurfaceSecondary)
            .clipShape(Capsule())
    }
}

struct AllowButtonStyle: ButtonStyle {
    let disabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(.black)
            .font(.satoshi(size: 14, weight: .medium))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(disabled ? .white.opacity(0.7) : .white)
            .clipShape(Capsule())
    }
}

extension Button {
    func applyStandardButtonStyle(
        disabled: Bool = false,
        padding: CGFloat = 15,
        fillWidth: Bool = true
    ) -> some View {
        buttonStyle(
            StandardStyle(
                disabled: disabled,
                padding: padding,
                fillWidth: fillWidth
            )
        ).disabled(disabled)
    }
    
    func applyCapsuleButtonStyle(
        disabled: Bool = false,
        padding: CGFloat = 15,
        fillWidth: Bool = true
    ) -> some View {
        buttonStyle(
            CapsuleStyle(
                disabled: disabled,
                padding: padding,
                fillWidth: fillWidth
            )
        ).disabled(disabled)
    }
}
