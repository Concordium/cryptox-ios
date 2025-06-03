//
//  ConfirmTransactionView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

struct ConfirmTransactionView: View {
    @ObservedObject var viewModel: TransferTokenViewModel
    @Binding var path: [NavigationPaths]
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack(alignment: .center, spacing: 30) {
                    VStack(spacing: 10) {
                        Text("\(viewModel.account.displayName)\n\(viewModel.account.address)")
                            .font(.satoshi(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Image("receive")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(viewModel.recepientAddress)
                            .font(.satoshi(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                    }
                    Divider()
                        .background(.white.opacity(0.1))
                    
                    VStack(spacing: 8) {
                        Text("Amount(\(viewModel.ticker)):")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                        Text(TokenFormatter().string(from: viewModel.amountTokenSend, decimalSeparator: ".", thousandSeparator: ","))
                            .font(.plexSans(size: 40, weight: .medium))
                            .dynamicTypeSize(.small ... .xxLarge)
                            .minimumScaleFactor(0.3)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .modifier(RadialGradientForegroundStyleModifier())
                        Text("Transaction fee ≈ \(GTU(intValue: Int(BigInt(stringLiteral: viewModel.tokenTransferModel.transaferCost?.cost ?? "0"))).displayValueWithCCDStroke())")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.grey4)
                    }
                    
                    if let memo = viewModel.addedMemo {
                        Divider()
                            .background(.white.opacity(0.1))
                        HStack(alignment: .top, spacing: 6) {
                            Image("Note")
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(memo.displayValue)
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 34)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 14)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: -0.5)
                        .stroke(.grey4.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
                SliderButton(text: "Submit transaction") {
                    path.append(.transferSendingStatus(TransferTokenConfirmViewModel(tokenTransferModel: viewModel.tokenTransferModel, transactionsService: ServicesProvider.defaultProvider().transactionsService(), storageManager: ServicesProvider.defaultProvider().storageManager())))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .modifier(AppBackgroundModifier())
    }
}
