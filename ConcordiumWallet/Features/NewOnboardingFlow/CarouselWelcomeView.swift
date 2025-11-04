//
//  CarouselWelcomeView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 30.10.2025.
//  Copyright © 2025 Concordium. All rights reserved.
//

import SwiftUI

struct CarouselWelcomeView: View {
    @State private var currentPage = 0
    private let totalPages = 2
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack(spacing: 16) {
            Image("launch_icon")
                .resizable()
                .frame(width: 64, height: 64)

            Text("smart.money.title".localized)
                .font(.satoshi(size: 24, weight: .medium))
                .foregroundStyle(.semanticContentPrimary)
                .padding(.bottom, 8)

            SimpleCarousel(pages: totalPages, index: $currentPage) { i in
                let index = i + 1
                carouselItem(
                    image: "graphic-landing-\(index)",
                    title: "carousel.sec\(index).headline".localized,
                    subtitle: "carousel.sec\(index).subheadline".localized
                )
            }

            Button(
                action: {
                    withAnimation {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        } else {
                            navigationManager.navigate(to: .welcomeScreen)
                        }
                    }
                }, label: {
                    HStack(spacing: 8) {
                        Text(continueButtonTitle)
                            .font(Font.satoshi(size: 14, weight: .medium))
                            .lineSpacing(24)
                            .foregroundColor(Color.Neutral.tint7)
                        if currentPage == 1 {
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                })
            .frame(height: 56)
            .background(.white)
            .cornerRadius(28, corners: .allCorners)
            .padding(.horizontal)
            .padding(.top, 30)
        }
        .padding(.top, 52)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    private func carouselItem(image: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(image)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(contentMode: .fit)
                .clipped()
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.satoshi(size: 20, weight: .medium))
                    .foregroundStyle(.semanticContentPrimary)
                Text(subtitle)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(.accentSecondary)
            }
        }
    }
    
    private var continueButtonTitle: String {
        switch currentPage {
        case 0:
            "continue_btn_title".localized
        default:
            "get_started_btn_title".localized
        }
    }
}

struct CapsuleDotsIndicator: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Group {
                    if i == index {
                        Capsule()
                            .frame(width: 40, height: 8)
                            .transition(.scale)
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Circle()
                            .frame(width: 8, height: 8)
                            .transition(.opacity)
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
            }
        }
        .foregroundStyle(.gray.opacity(0.7))
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: index)
    }
}

struct SimpleCarousel<Content: View>: View {
    let pages: Int
    @Binding var index: Int
    @ViewBuilder var page: (Int) -> Content

    var body: some View {
        VStack(spacing: 36) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(0..<pages, id: \.self) { i in
                                page(i)
                                    .frame(width: UIScreen.main.bounds.width - 32)
                                    .id(i)
                            }
                        }
                    }
                    .scrollDisabled(true)
                    .onAppear { proxy.scrollTo(index, anchor: .leading) }
                    .onChange(of: index) { newIndex in
                        withAnimation { proxy.scrollTo(newIndex, anchor: .leading) }
                    }
                }

            CapsuleDotsIndicator(count: pages, index: index)
        }
    }
}
