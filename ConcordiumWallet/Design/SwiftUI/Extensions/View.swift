//
//  View.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 18.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func ignoreAnimations() -> some View {
        transaction { transaction in
            transaction.animation = nil
        }
    }
}

