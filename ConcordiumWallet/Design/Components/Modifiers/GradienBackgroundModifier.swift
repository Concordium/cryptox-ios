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
