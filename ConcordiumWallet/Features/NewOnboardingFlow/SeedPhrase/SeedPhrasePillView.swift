//
//  SeedPhrasePillView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct SeedPhrasePillView: View {
    let word: String
    let idx: Int?
    
    var body: some View {
        HStack(spacing: 6) {
            if let idx = idx {
                Text("\(idx)")
                    .font(.plexMono(size: 12, weight: .regular))
                    .foregroundStyle(Color.MineralBlue.tint2)
            }
            Text(word)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(Color.Neutral.tint2)
                .lineLimit(1)
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .background(Color.Neutral.tint5)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    SeedPhrasePillView(word: "Pill", idx: 0)
}
