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
    let isSelected: Bool
    let onCheckMarkTapGesture: () -> Void
    
    var body: some View {
        HStack {
            if let url = token.metadata.thumbnail?.url {
                CryptoImage(url: url.toURL, size: .medium)
                    .clipped()
            }
            VStack(spacing: 5) {
                Text(token.metadata.name ?? "")
                    .foregroundColor(.white)
                    .font(.satoshi(size: 15, weight: .medium))
                Text(token.tokenId)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 13, weight: .regular))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .overlay {
            if isSelected {
                RoundedCorner(radius: 24, corners: .allCorners)
                    .stroke(Color.blackAditional, lineWidth: 1)
            }
        }
        .overlay(alignment: .trailing) {
                selectionOverlay
        }
    }
    
    
    private var selectionOverlay: some View {
        let imageView = (isSelected ? Image("icon_selection") : Image(systemName: "circle"))
            .padding(.trailing, 12)
            .onTapGesture {
                onCheckMarkTapGesture()
            }

        if #available(iOS 17.0, *) {
            return imageView
                .contentTransition(.symbolEffect(.replace))
        } else {
            return imageView
        }
    }
}
