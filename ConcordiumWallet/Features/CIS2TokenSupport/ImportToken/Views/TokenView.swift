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
            TokenListRow(
                data: cellData(for: token),
                mode: .add,
                isSelected: isSelected,
                hideTokenAction: nil
            )
            Spacer()
            
            RoundedSquareView(needToFill: $isSelected)
                .onTapGesture {
                    isSelected.toggle()
                }
                .frame(width: 24, height: 24)
        }
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .onChange(of: isSelected) { _ in
            onCheckMarkTapGesture()
        }
    }
    
    func cellData(for token: UnifiedToken) -> TokenListCellData {
        switch token {
        case .cis2(let cis2Token):
            let iconView: AnyView
            if let url = cis2Token.metadata.thumbnail?.url {
                iconView = AnyView(CryptoImage(url: url.toURL, size: .custom(width: 40, height: 40)))
            } else {
                iconView = AnyView(Image("placeholder-crypto-token").resizable())
            }
            return TokenListCellData(
                id: cis2Token.id,
                icon: iconView,
                title: token.name,
                subtitle: "CIS-2",
                amount: "",
                secondaryAmount: nil,
                tokenImage: .cis2,
                showDenyIcon: false,
                isCCD: false
            )
        case .plt(let pltToken):
            return TokenListCellData(
                id: pltToken.id,
                icon: AnyView(Image("placeholder-crypto-token").resizable().clipShape(Circle())),
                title: pltToken.tokenState.moduleState.name,
                subtitle: "PLT",
                amount: TokenFormatter.formatPLTTokenAmount(amount: pltToken.tokenState.totalSupply.value),
                secondaryAmount: nil,
                tokenImage: .plt,
                showDenyIcon: pltToken.tokenState.moduleState.denyList || !pltToken.tokenState.moduleState.allowList,
                isCCD: false
            )
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


struct TokenListCellData {
    let id: Int
    let icon: AnyView
    let title: String
    let subtitle: String?
    let amount: String
    let secondaryAmount: String?
    let tokenImage: TokenImage?
    let showDenyIcon: Bool
    let isCCD: Bool
}

enum TokenViewMode {
    case view, manage, add
}

enum TokenImage: String {
    case plt = "shield-square-crypto"
    case cis2 = "coin-crypto-cis-2"
}
struct TokenListRow: View {
    let data: TokenListCellData
    let mode: TokenViewMode
    let isSelected: Bool
    let hideTokenAction: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            data.icon.frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(data.title)
                        .foregroundColor(.white)
                        .font(.satoshi(size: 15, weight: .medium))
                    if data.showDenyIcon {
                        Image("circled-x-block-deny")
                            .renderingMode(.template)
                            .foregroundColor(.accentSecondary)
                    }
                }
                if let subtitle = data.subtitle, let tokenImage = data.tokenImage {
                    HStack(spacing: 4) {
                        Image(tokenImage.rawValue)
                            .resizable()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(data.tokenImage == .cis2 ? .white.opacity(0.4) : .accentSecondary)
                        Text(subtitle)
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(data.tokenImage == .cis2 ? .white.opacity(0.4) : .accentSecondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(data.amount)
                    .font(.satoshi(size: 15, weight: .medium))
                    .tint(.white)
                if let secondary = data.secondaryAmount{
                    Text(secondary)
                        .font(.satoshi(size: 12, weight: .regular))
                        .tint(.MineralBlue.blueish3)
                        .opacity(0.5)
                }
            }
            
            if mode == .manage && !data.isCCD {
                Text("Hide token")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.semanticContentSecondary)
                    .padding(6)
                    .onTapGesture { hideTokenAction?() }
                    .overlay(
                        RoundedRectangle(cornerRadius: 9999)
                            .stroke(Color.semanticBorderTertiary, lineWidth: 1)
                    )
            }
            
            if mode == .view {
                Image("caretRight")
                    .renderingMode(.template)
                    .foregroundStyle(.grey4)
                    .frame(width: 30, height: 40)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }
}
