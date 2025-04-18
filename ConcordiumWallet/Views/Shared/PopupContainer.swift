//
//  PopupContainer.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct PopupContainer<Content: View>: View {
    
    var icon: String
    var title: String
    var subtitle: String
    let content: Content
    var dismissAction: (() -> Void)?
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.6), .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea(.all)
            
            ZStack {
                VStack(spacing: 16) {
                    Image(icon)
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.satoshi(size: 20, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.08, green: 0.09, blue: 0.11))
                        Text(subtitle)
                            .font(.satoshi(size: 14, weight: .regular))
                            .multilineTextAlignment(.center)
                            .lineSpacing(7)
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                    content
                    .frame(minHeight: 44)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                .padding(.horizontal, 24)
                .overlay(alignment: .topTrailing) {
                    Button {
                        Vibration.vibrate(with: .light)
                        dismissAction?()
                    } label: {
                        Image("unshield_close_popup_icon")
                            .contentShape(.rect)
                    }
                    .offset(x: -12, y: 12)
                }
            }
            .modifier(FloatingGradientBGStyleModifier())
            .cornerRadius(20)
            .padding(.horizontal, 32)
            .clipped()
        }
    }
}
