//
//  EarnAmountInputView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct EarnAmountInputView: View {
    
    @ObservedObject var viewModel: StakeAmountInputViewModel
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .bottom) {
                    DecimalNumberTextField(decimalValue: $viewModel.amountDecimal, fraction: $viewModel.fraction)
                        .tint(.white)
                    
                    Button {
                        viewModel.sendAll()
                    } label: {
                        Text("Max")
                            .underline(true, pattern: .solid)
                            .font(.satoshi(size: 15, weight: .medium))
                            .foregroundStyle(.greyAdditional)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                HStack {
                    Text("~ \(viewModel.euroEquivalentForCCD) EUR")
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                    Spacer()
                    Text("Transaction fee")
                        .font(.satoshi(size: 12, weight: .medium))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                    Text(viewModel.transactionFee ?? "")
                        .font(.satoshi(size: 12, weight: .medium))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                }
                
                //                if !viewModel.isInsuficientFundsErrorHidden {
                //                    Text("sendFund.insufficientFunds".localized)
                //                        .foregroundColor(Color(hex: 0xFF163D))
                //                        .font(.satoshi(size: 15, weight: .medium))
                //                }
                
                SendTokenCell(tokenType: .ccd(displayAmount: "\(viewModel.account?.forecastAtDisposalBalance ?? 0)"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
}
