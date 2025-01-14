//
//  TokenView.swift
//  CryptoX
//
//  Created by Max on 05.06.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct TokenView: View {
    let token: CIS2Token
    @State var isSelected: Bool
    let onCheckMarkTapGesture: () -> Void
    
    var body: some View {
        HStack {
            if let url = token.metadata.thumbnail?.url {
                CryptoImage(url: url.toURL, size: .medium)
                    .clipped()
            }
            VStack(spacing: 8) {
                Text(token.metadata.name ?? "")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(token.tokenId)
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            Spacer()
            
            RoundedSquareView(needToFill: $isSelected)
                .onTapGesture {
                    isSelected.toggle()
                }
                .frame(width: 24, height: 24)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
        .onChange(of: isSelected) { _ in
            onCheckMarkTapGesture()
        }
    }
}

struct RoundedSquareView: View {
    @Binding var needToFill: Bool
    
    var body: some View {
        ZStack {
            // Outer rounded square
            RoundedRectangle(cornerRadius: 5)
                .stroke(.white, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            // Inner rounded square
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .opacity(needToFill ? 1 : 0)
        }
        .frame(width: 24, height: 24)
        .background(Color(red: 0.13, green: 0.14, blue: 0.15))
    }
}

#Preview(body: {
    TokenView(token: CIS2Token(entity: CIS2TokenEntity()), isSelected: false) {
        
    }
})
