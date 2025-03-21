//
//  HomeScreenViewSkeleton.swift
//  CryptoX
//
//  Created by Max on 04.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct HomeScreenViewSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Placeholder for top bar
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 32)
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                
                // Placeholder for balance section
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 40)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                
                // Placeholder for action buttons
                HStack {
                    ForEach(0..<5) { _ in
                        VStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 12)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 18)
                
                // Placeholder for account states
                Spacer()
                    .padding(.bottom, 40)
                ForEach(0..<4) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 50)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                }
            }
            .redacted(reason: .placeholder)
            .padding(.bottom, 20)
        }
        .modifier(AppBackgroundModifier())
        .onAppear {
            withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
