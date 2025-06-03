//
//  BottomSheet.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 22.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

fileprivate enum Constants {
    static let radius: CGFloat = 16
    static let indicatorHeight: CGFloat = 6
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.3
}

struct BottomSheet<Content: View>: View {
    @Binding var isShowing: Bool
    private let content: Content
    
    @GestureState private var translation: CGFloat = 0

    init(isShowing: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isShowing = isShowing
        self.content = content()
    }

    var body: some View {
        GeometryReader(content: { geometry in
            ZStack(alignment: .bottom) {
                if (isShowing) {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .zIndex(1)
                        .onTapGesture {
                            isShowing.toggle()
                        }
                    content
                        .padding(.bottom, 42)
                        .transition(.move(edge: .bottom))
                        .background(
                            Color(uiColor: .white)
                        )
                        .background {
                            Image("modal_bg").resizable().ignoresSafeArea(.all)
                        }
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .zIndex(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .animation(.snappy(duration: 0.2), value: isShowing)
            .gesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 50 {
                            isShowing = false
                        }
                    }
            )
        })
    }
}
