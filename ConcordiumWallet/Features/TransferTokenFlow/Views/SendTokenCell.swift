//
//  SendTokenCell.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct SendTokenCell: View {
    enum TokenType {
        case ccd(displayAmount: String)
        case cis2(token: CIS2Token, availableAmount: String)
    }

    let tokenType: TokenType
    let hideCaretRight: Bool
    let text: String
    
    init(tokenType: TokenType, hideCaretRight: Bool = false, text: String = "accounts.atdisposal".localized) {
        self.tokenType = tokenType
        self.hideCaretRight = hideCaretRight
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 17) {
            switch tokenType {
            case .ccd(let displayAmount):
                Image("ccd")
                    .resizable()
                    .frame(width: 40, height: 40)
                HStack(spacing: 0) {
                    Text("CCD")
                        .font(.satoshi(size: 15, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(displayAmount)
                        .font(.satoshi(size: 15, weight: .medium))
                        .tint(.white)
                    Text(text)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                }

            case .cis2(let token, let availableAmount):
                if let url = token.metadata.thumbnail?.url {
                    CryptoImage(url: url.toURL, size: .medium)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                Text(token.metadata.symbol ?? token.metadata.name ?? "")
                    .font(.satoshi(size: 15, weight: .medium))
                Spacer()
                Text(availableAmount)
                    .font(.satoshi(size: 15, weight: .medium))
                    .tint(.white)
            }
            Image("caretRight")
                .renderingMode(.template)
                .foregroundStyle(.grey4)
                .frame(width: 30, height: 40)
                .opacity(hideCaretRight ? 0 : 1)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}
