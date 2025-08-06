//
//  TokenView.swift
//  CryptoX
//
//  Created by Max on 05.06.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct TokenView: View {
    let token: UnifiedToken
    @State var isSelected: Bool
    let onCheckMarkTapGesture: () -> Void
    
    var body: some View {
        HStack {
            switch token {
            case .cis2(let cIS2Token):
                if let url = cIS2Token.metadata.thumbnail?.url {
                    CryptoImage(url: url.toURL, size: .medium)
                        .clipped()
                }
            case .plt( _):
                Image("placeholder-crypto-token")
                    .resizable()
                    .clipShape(Circle())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }
                Text(token.name)
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(.white)
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
    TokenView(token: UnifiedToken.cis2(CIS2Token(entity: CIS2TokenEntity())), isSelected: false) {
        
    }
})
