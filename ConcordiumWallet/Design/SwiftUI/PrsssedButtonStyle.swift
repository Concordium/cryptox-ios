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
