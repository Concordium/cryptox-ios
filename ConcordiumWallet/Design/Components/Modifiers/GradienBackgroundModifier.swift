//
//  GradienBackgroundModifier.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 04.08.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.blackMain)
    }
}

struct NavigationViewModifier: ViewModifier {
    
    let navigationTitle: String
    let leadingAction: (() -> Void)?
    let trailingAction: (() -> Void)?
    let trailingIcon: Image?
    let iconSize: CGSize?

    @State private var showBackButton = false
    @State private var isBackButtonTapped = false

    init(title: String, backAction: (() -> Void)? = nil, trailingAction: (() -> Void)? = nil, trailingIcon: Image? = nil, iconSize: CGSize? = nil) {
        self.navigationTitle = title
        self.leadingAction = backAction
        self.trailingAction = trailingAction
        self.trailingIcon = trailingIcon
        self.iconSize = iconSize
    }
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            VStack {
                ZStack {
                    Text(navigationTitle)
                        .font(.satoshi(size: 17, weight: .medium))
                        .foregroundColor(.white)

                    HStack {
                        if let leadingAction = leadingAction {
                            Button(action: {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isBackButtonTapped = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    leadingAction()
                                }
                            }) {
                                Image("ico_back")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.gray)
                                    .opacity(isBackButtonTapped ? 0 : (showBackButton ? 1 : 0))
                                    .animation(.easeOut(duration: 0.3), value: isBackButtonTapped)
                            }
                        }
                        Spacer()

                        if let trailingAction = trailingAction, let trailingIcon = trailingIcon {
                            Button(action: trailingAction) {
                                trailingIcon
                                    .resizable()
                                    .frame(width: iconSize?.width ?? 32, height: iconSize?.height ?? 32)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .modifier(AppBackgroundModifier())
            }
            content
                .navigationBarBackButtonHidden()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width > 100 {
                                leadingAction?()
                            }
                        }
                )
                .onAppear {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showBackButton = true
                    }
                }
        }
    }
}

struct RadialGradientForegroundStyleModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                RadialGradient(
                    colors:
                        [Color(red: 0.93, green: 0.85, blue: 0.75),
                        Color(red: 0.64, green: 0.6, blue: 0.89),
                        Color(red: 0.62, green: 0.95, blue: 0.92)]
                    ,
                    center: .topLeading,
                    startRadius: 50,
                    endRadius: 300
                )
            )
            .saturation(2)
    }
}


struct FloatingGradientBGStyleModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors:
                                                [Color(red: 0.62, green: 0.95, blue: 0.92),
                                                 Color(red: 0.93, green: 0.85, blue: 0.75),
                                                 Color(red: 0.64, green: 0.6, blue: 0.89)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
            )
    }
}
