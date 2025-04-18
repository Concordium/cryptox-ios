//
//  ValidatorAmountInputView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorAmountInputView: View {
    
    @ObservedObject var viewModel: ValidatorAmountInputViewModel
    @FocusState var isFocused: Bool
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .bottom) {
                DecimalNumberTextField(decimalValue: $viewModel.amountDecimal, fraction: $viewModel.fraction, ticker: "CCD")
                    .focused($isFocused)
                    .tint(.white)
                    .frame(alignment: .leading)
                    .onChange(of: isFocused) { focused in
                        viewModel.hasStartedInput = focused
                    }
                
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
                Text("Transaction fee " + (viewModel.transactionFee ?? "0.00") + " CCD")
                    .font(.satoshi(size: 12, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            }
            
            if let error = viewModel.amountErrorMessage, viewModel.hasStartedInput || viewModel.isAmountLocked {
                Text(error)
                    .foregroundColor(Color(hex: 0xFF163D))
                    .font(.satoshi(size: 15, weight: .medium))
            }
            
            SendTokenCell(tokenType: .ccd(displayAmount: GTU(intValue: viewModel.account.forecastBalance).displayValueWithTwoNumbersAfterDecimalPoint()),
                          hideCaretRight: true,
                          text: "available.for.staking".localized)
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text("restake.reward".localized)
                        .font(.satoshi(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    CustomToggle(isOn: $viewModel.isRestakeSelected)
                }
                Text("restake.reward.desc".localized)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)
            
            Spacer()
            
            RoundedButton(action: {
                viewModel.pressedContinue()
            },
                          title: "continue_btn_title".localized,
                          isDisabled: !viewModel.isContinueEnabled)
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
        .modifier(AlertModifier(alertOptions: viewModel.alertOptions ?? SwiftUIAlertOptions(title: nil, message: nil, actions: []), isPresenting: $viewModel.showAlert))
    }
}
