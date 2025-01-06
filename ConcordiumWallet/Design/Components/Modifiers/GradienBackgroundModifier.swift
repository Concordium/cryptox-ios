//
//  GradienBackgroundModifier.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 04.08.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct GradienBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
            )
    }
}

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.blackMain)
    }
}

struct RadialGradientForegroundStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(RadialGradient(
                colors: [
                    Color(red: 0.62, green: 0.95, blue: 0.92),
                    Color(red: 0.93, green: 0.85, blue: 0.75),
                    Color(red: 0.64, green: 0.6, blue: 0.89)
                ],
                center: .topLeading,
                startRadius: 50,
                endRadius: 300
            ))
    }
}
