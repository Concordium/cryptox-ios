//
//  AccountDetailView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 29.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt
import Combine

enum AccountDetailAccount: Equatable, Identifiable, Hashable {
    case ccd(amount: GTU),
         token(token: CIS2Token, amount: String),
         plt(token: AccountPLTToken, amount: String)
    
    var stableId: String {
        switch self {
        case .ccd:
            return "ccd"
        case .token(let t, _):
            return "cis2:\(t.contractAddress.index):\(t.tokenId)"
        case .plt(let t, _):
            return "plt:\(t.token.tokenID)"
        }
    }

    var id: Int { stableId.hashValue }
    
    var name: String {
        switch self {
            case .ccd: return "ccd"
            case .token(let token, _): return token.metadata.name ?? ""
            case .plt(token: let token, _): return token.token.tokenState.moduleState.name
        }
    }
    
    var cis2Token: CIS2Token? {
        switch self {
            case .ccd, .plt: return nil
            case let .token(token, _): return token
        }
    }
    
    var isCCDOrCis2: Bool {
        switch self {
        case .ccd, .token: return true
        default: return false
        }
    }
    
    var pltToken: AccountPLTToken? {
        switch self {
            case .ccd, .token: return nil
            case let .plt(token, _): return token
        }
    }
}

struct CCDTokenView: View {
    let account: AccountDetailAccount
    
    var body: some View {
        HStack {
            switch account {
                case .ccd(let amount):
                    Image("icon_ccd")
                        .resizable()
                        .frame(width: 40, height: 40)
                Text(amount.displayValue() + " CCD")
                        .foregroundColor(.white)
                        .font(.satoshi(size: 15, weight: .medium))
                case .token(let token, let amount):
                    if let url = token.metadata.thumbnail?.url {
                        CryptoImage(url: url.toURL, size: .medium)
                            .aspectRatio(contentMode: .fit)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TokenFormatter()
                            .string(from: BigDecimal(BigInt(stringLiteral: amount), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ","))
                            .foregroundColor(.white)
                        .font(.satoshi(size: 15, weight: .medium))
                        Text(token.metadata.name ?? "")
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        .font(.satoshi(size: 13, weight: .medium))
                    }
            case .plt(let token, let amount):
                Image("placeholder-crypto-token")
                    .resizable()
                    .clipShape(Circle())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.tokenAccountState.balance.value)
                        .foregroundColor(.white)
                    .font(.satoshi(size: 15, weight: .medium))
                    Text(token.token.tokenState.moduleState.name)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    .font(.satoshi(size: 13, weight: .medium))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
