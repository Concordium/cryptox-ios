//
//  NewsPageView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 01.11.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct NewsPageView: View {
    @Binding var selectedTab: Int
    let spacing: CGFloat = 8
    let views: () -> [AnyView]
    
    @State private var dragOffset: CGFloat = 0
    var viewCount: Int { views().count }
    
    var body: some View {
        VStack(spacing: spacing) {
            GeometryReader { geo in
                let viewWidth = viewCount > 1 ? ((geo.size.width * 0.85) - 8) : (geo.size.width - 32)
                let edgeOffset: CGFloat = viewWidth * 0.15
                
                LazyHStack(spacing: spacing) {
                    ForEach(0..<viewCount, id: \.self) { idx in
                        views()[idx]
                            .frame(width: viewWidth)
                            .cornerRadius(12)
                    }
                }
                .offset(x: -CGFloat(selectedTab) * (viewWidth + spacing) + dragOffset + ((selectedTab == viewCount - 1 && viewCount > 1) ? edgeOffset : 0))
                .padding(.leading, selectedTab == 0 ? 16 : 0)
                .padding(.trailing, selectedTab == viewCount - 1 ? 16 : 0)
                .frame(width: viewWidth, alignment: .leading)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold = viewWidth / 2
                            let predictedEnd = value.predictedEndTranslation.width
                            
                            if abs(predictedEnd) > threshold {
                                selectedTab += (predictedEnd > 0) ? -1 : 1
                            }
                            
                            selectedTab = max(0, min(selectedTab, viewCount - 1))
                            
                            withAnimation(.easeOut) {
                                dragOffset = 0
                            }
                        }
                )
                .animation(dragOffset == 0 ? .easeOut : .none, value: selectedTab)
            }
            .background(.clear)
            .frame(height: 132)
            
            HStack {
                ForEach(0..<viewCount, id: \.self) { idx in
                    Circle()
                        .frame(width: 8)
                        .foregroundColor(idx == selectedTab ? .primary : .secondary.opacity(0.5))
                        .onTapGesture {
                            withAnimation {
                                selectedTab = idx
                            }
                        }
                }
            }
        }
    }
}
