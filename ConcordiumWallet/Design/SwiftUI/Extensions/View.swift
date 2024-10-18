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

extension View {
    func errorAlert(error: Binding<GeneralAppError?>, cancelTitle: String = "errorAlert.cancelButton".localized, action: ((GeneralAppError?) -> Void)?) -> some View {
        return alert(isPresented: .constant(error.wrappedValue != nil), error: error.wrappedValue) { _ in
            switch error.wrappedValue {
                case .noCameraAccess:
                    Button(error.wrappedValue?.actionButtontitle ?? "") {
                        action?(error.wrappedValue)
                    }
                case .none: EmptyView()
                default: EmptyView()
            }
            Button(cancelTitle, role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
