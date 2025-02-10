//
//  ToastGradientView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 10.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ToastGradientView: View {
    @State private var isVisible = false
    var title: String
    var imageName: String

    var body: some View {
        VStack {
            if isVisible {
                VStack(alignment: .center) {
                    HStack(spacing: 16) {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.stone)
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(.grey2)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 43)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.62, green: 0.95, blue: 0.92),
                                    Color(red: 0.93, green: 0.85, blue: 0.75),
                                    Color(red: 0.64, green: 0.6, blue: 0.89)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 400
                            )
                        )
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: isVisible)
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

struct Toast: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let toastContent: () -> AnyView
    let position: Alignment
    
    func body(content: Content) -> some View {
        ZStack(alignment: position) {
            content
            if isPresented {
                toastContent()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: isPresented)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}
