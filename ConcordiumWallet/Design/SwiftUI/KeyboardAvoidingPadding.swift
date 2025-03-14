//
//  KeyboardAvoidingPadding.swift
//  CryptoX
//
//  Created by Zhanna Komar on 07.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct KeyboardAvoidingPadding: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    private var publisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(publisher) { height in
                withAnimation {
                    keyboardHeight = height
                }
            }
    }
}
