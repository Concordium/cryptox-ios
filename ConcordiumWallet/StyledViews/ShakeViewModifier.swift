//
//  ShakeViewModifier.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ShakeEffect: GeometryEffect {
    var shakesPerUnit: CGFloat = 3
    var amount: CGFloat = 10
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

struct ShakeViewModifier: ViewModifier {
    var animating: Bool

    @State private var shakeTrigger: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: animating ? shakeTrigger : 0))
            .onAppear {
                if animating {
                    withAnimation(
                        Animation.linear(duration: 0.6)
                            .repeatCount(1, autoreverses: false)
                    ) {
                        shakeTrigger = 1
                    }
                }
            }
    }
}
