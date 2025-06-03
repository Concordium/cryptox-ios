//
//  StakeDetailsView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct StakeDetailsView: View {
    
    private let rows: [StakeRowViewModel]
    
    init(rows: [StakeRowViewModel]) {
        self.rows = rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rows, id: \.id) { row in
                    keySection(title: row.headerLabel, key: row.valueLabel)
                    if row.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            .padding([.leading, .top], 14)
            .padding(.trailing, 26)
            .padding(.bottom, 18)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    private func keySection(title: String, key: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            Text(key)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
