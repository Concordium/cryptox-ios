//
//  PrsssedButtonStyle.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct PressedButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    var backgroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18.5)
            .frame(maxWidth: .infinity)
            .background(
                isDisabled
                    ? Color.surfacePrimaryDisabled
                    : (configuration.isPressed
                        ? Color(red: 0.84, green: 0.89, blue: 0.94)
                        : backgroundColor)
            )
            .foregroundColor(
                isDisabled
                    ? Color.contentPrimaryDisabled
                    : (configuration.isPressed
                        ? Color(red: 0.11, green: 0.29, blue: 0.5)
                        : Color.blackMain)
            )
            .cornerRadius(28)
            .disabled(isDisabled)
    }
}

struct PressedPlainButtonStyle: ButtonStyle {
    @State private var isPressed: Bool = false
    var action: () -> Void
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isPressed ? .buttonPressed : .white)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if configuration.isPressed {
                            action()
                        }
                    }
                }
            }
    }
}

struct NoStyleButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension Button {
    func noStyle() -> some View {
        self.buttonStyle(NoStyleButton())
    }
}
