//
//  SliderButton.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct SliderButton: View {
    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted: Bool = false
    let text: String
    let action: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Static background
                RoundedRectangle(cornerRadius: 48)
                    .fill(Color.MineralBlue.blueish3)
                    .frame(height: 50)
                
                // Text displayed in the center
                Text(text)
                    .foregroundColor(.grey2)
                    .font(.satoshi(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.62, green: 0.95, blue: 0.92),
                        Color(red: 0.93, green: 0.85, blue: 0.75),
                        Color(red: 0.64, green: 0.6, blue: 0.89)
                    ]),
                    center: .leading,
                    startRadius: 20,
                    endRadius: dragOffset + 100 // Adjust radius based on drag offset
                )
                .frame(width: dragOffset + 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 48))
                .padding(.leading, 1)
                
                // Draggable arrow button
                RoundedRectangle(cornerRadius: 48)
                    .fill(.grey2)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image("ico_arrow")
                            .foregroundColor(Color.MineralBlue.blueish3)
                    )
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isCompleted {
                                    // Restrict movement within bounds
                                    let maxWidth = geometry.size.width - 48
                                    dragOffset = min(max(0, value.translation.width), maxWidth)
                                }
                            }
                            .onEnded { value in
                                let maxWidth = geometry.size.width - 48
                                if dragOffset >= maxWidth {
                                    isCompleted = true
                                    action()
                                } else {
                                    // Reset if not completed
                                    withAnimation {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .padding(.leading, 1)
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    SliderButton(text: "Drag to submit", action: {
        
    })
}
