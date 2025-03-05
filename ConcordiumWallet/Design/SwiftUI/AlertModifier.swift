//
//  AlertModifier.swift
//  CryptoX
//
//  Created by Zhanna Komar on 05.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum AlertActionStyle {
    case plain
    case styled
}
struct SwiftUIAlertAction {
    let name: String
    let completion: (() -> Void)?
    let style: AlertActionStyle
}

struct SwiftUIAlertOptions {
    let title: String?
    let message: String?
    let actions: [SwiftUIAlertAction]
}

struct AlertModifier: ViewModifier {
    var alertOptions: SwiftUIAlertOptions
    @Binding var isPresenting: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresenting {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                AlertView(alertOptions: alertOptions, isPresenting:  $isPresenting)
                            )
                            .transition(.opacity)
                            .animation(.easeInOut, value: isPresenting)
                    }
                }
            )
    }
}

struct AlertView: View {
    var alertOptions: SwiftUIAlertOptions
    @Binding var isPresenting: Bool
    @State private var actionTapped: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            if let title = alertOptions.title {
                Text(title)
                    .font(.satoshi(size: 16, weight: .semibold))
                    .foregroundStyle(.grey1)
            }
            if let message = alertOptions.message {
                Text(message)
                    .font(.satoshi(size: 15, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.grey1)
            }
            VStack(spacing: 16) {
                ForEach(alertOptions.actions, id: \.name) { action in
                    if action.style == .styled {
                        Button {
                            isPresenting = false
                            action.completion?()
                        } label: {
                            Text(action.name)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                        .background(.blackMain)
                        .cornerRadius(21)
                    } else {
                        Text(action.name)
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundStyle(actionTapped ? .grey4 : .blackMain)
                            .onTapGesture {
                                actionTapped = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    actionTapped = false
                                    isPresenting = false
                                    action.completion?()
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .frame(width: 327, alignment: .top)
        .modifier(FloatingGradientBGStyleModifier())
        .cornerRadius(16)
    }
}
