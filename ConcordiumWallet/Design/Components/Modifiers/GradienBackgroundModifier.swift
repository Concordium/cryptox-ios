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
    let tralingIcon: Image?
    let iconSize: CGSize?
    
    init(title: String, backAction: (() -> Void)? = nil, trailingAction: (() -> Void)? = nil, trailingIcon: Image? = nil, iconSize: CGSize? = nil) {
        self.navigationTitle = title
        self.leadingAction = backAction
        self.trailingAction = trailingAction
        self.tralingIcon = trailingIcon
        self.iconSize = iconSize
    }
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if leadingAction != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            leadingAction?()
                        } label: {
                            Image("ico_back")
                                .resizable()
                                .foregroundColor(.greySecondary)
                                .frame(width: 32, height: 32)
                                .contentShape(.circle)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(navigationTitle)
                            .font(.satoshi(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                    }
                }
                
                if trailingAction != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            trailingAction?()
                        } label: {
                            if let tralingIcon {
                                tralingIcon
                                    .resizable()
                                    .foregroundColor(.greySecondary)
                                    .frame(width: iconSize?.width ?? 32, height: iconSize?.height ?? 32)
                                    .contentShape(.circle)
                            }
                        }
                    }
                }
            }
    }
}

struct RadialGradientForegroundStyleModifier: ViewModifier {
    @State private var animated = false
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                RadialGradient(
                    colors: animated ? [
                        Color(red: 0.93, green: 0.85, blue: 0.75),
                        Color(red: 0.64, green: 0.6, blue: 0.89),
                        Color(red: 0.62, green: 0.95, blue: 0.92)
                    ] : [
                        Color(red: 0.62, green: 0.95, blue: 0.92),
                        Color(red: 0.93, green: 0.85, blue: 0.75),
                        Color(red: 0.64, green: 0.6, blue: 0.89)
                    ],
                    center: animated ? .bottomTrailing : .topLeading,
                    startRadius: animated ? 100 : 50,
                    endRadius: animated ? 400 : 300
                )
            )
            .saturation(2)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animated.toggle()
                }
            }
    }
}


struct FloatingGradientBGStyleModifier: ViewModifier {
    @State private var animated = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: animated ?
                                               [Color(red: 0.93, green: 0.85, blue: 0.75),
                                                Color(red: 0.64, green: 0.6, blue: 0.89),
                                                Color(red: 0.62, green: 0.95, blue: 0.92)]
                                               :
                                                [Color(red: 0.62, green: 0.95, blue: 0.92),
                                                 Color(red: 0.93, green: 0.85, blue: 0.75),
                                                 Color(red: 0.64, green: 0.6, blue: 0.89)]),
                            center: animated ? .topTrailing : .center,
                            startRadius: animated ? 50 : 0,
                            endRadius: animated ? 500 : 400
                        )
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                            animated.toggle()
                        }
                    }
            )
    }
}
