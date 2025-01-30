//
//  ChooseTokenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import BigInt

struct ChooseTokenView: View {
    @ObservedObject var viewModel: AccountDetailViewModel
    @ObservedObject var transferTokenViewModel: TransferTokenViewModel
    var onTokenSelected: (() -> Void)
    
    var body: some View {
        List {
            ForEach(viewModel.accounts, id: \.id) { token in
                switch token {
                case .ccd(_):
                    SendTokenCell(tokenType: .ccd(displayAmount: transferTokenViewModel.atDisposalCCDDisplayAmount))
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            transferTokenViewModel.tokenTransferModel.tokenType = .ccd
                            onTokenSelected()
                        }
                case .token(let token, let amount):
                    SendTokenCell(tokenType: .cis2(token: token, availableAmount: TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: amount), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ",")))
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            transferTokenViewModel.tokenTransferModel.tokenType = .cis2(token)
                            onTokenSelected()
                        }
                }
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .padding(.horizontal, 18)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
}
