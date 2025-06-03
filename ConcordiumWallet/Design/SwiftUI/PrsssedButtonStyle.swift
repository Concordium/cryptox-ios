//
//  PrsssedButtonStyle.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 18.5)
            .background(configuration.isPressed ? Color(red: 0.84, green: 0.89, blue: 0.94) : Color.white)
            .foregroundColor(configuration.isPressed ? Color(red: 0.11, green: 0.29, blue: 0.5) : .blackMain)
            .cornerRadius(28)
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
