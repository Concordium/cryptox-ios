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
    var alertOptions: SwiftUIAlertOptions?
    @Binding var isPresenting: Bool
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isPresenting ? 2.0 : 0)
            .overlay(
                Group {
                    if isPresenting {
                                AlertView(alertOptions: alertOptions, isPresenting:  $isPresenting)
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                            .animation(.easeInOut, value: isPresenting)
                    }
                }
            )
    }
}

struct AlertView: View {
    var alertOptions: SwiftUIAlertOptions?
    @Binding var isPresenting: Bool
    @State private var actionTapped: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            if let title = alertOptions?.title {
                Text(title)
                    .font(.satoshi(size: 16, weight: .semibold))
                    .foregroundStyle(.grey1)
            }
            if let message = alertOptions?.message {
                Text(message)
                    .font(.satoshi(size: 15, weight: .regular))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.grey1)
            }
            VStack(spacing: 16) {
                if let actions = alertOptions?.actions {
                    ForEach(actions, id: \.name) { action in
                        if action.style == .styled {
                            Button {
                                withAnimation {
                                    isPresenting = false
                                }
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
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .frame(alignment: .top)
        .modifier(FloatingGradientBGStyleModifier())
        .cornerRadius(16)
    }
}

struct VisualEffectBlurView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: blurStyle)
        let effectView = UIVisualEffectView(effect: effect)
        return effectView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No updates required for this effect.
    }
}
