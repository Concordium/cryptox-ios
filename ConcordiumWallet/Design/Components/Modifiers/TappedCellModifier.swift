//
//  TappedCellModifier.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct TappedCellEffect: ViewModifier {
    @State private var isTapped: Bool = false
    var onTap: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .background(isTapped ? .selectedCell : Color(red: 0.09, green: 0.1, blue: 0.1))
            .cornerRadius(12)
            .onTapGesture {
                isTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isTapped = false
                    onTap?()
                }
            }
    }
}
