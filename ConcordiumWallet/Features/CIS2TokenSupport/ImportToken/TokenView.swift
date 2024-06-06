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
    
    var body: some View {
        HStack {
            if let url = token.metadata.thumbnail?.url {
                CryptoImage(url: url.toURL, size: .medium)
                    .clipped()
            }
            Text(token.metadata.name ?? "")
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium))
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
            if isSelected {
                selectionOverlay
            }
        }
    }
    
    
    private var selectionOverlay: some View {
        Image("icon_selection")
            .padding(.trailing, 12)
    }
}
