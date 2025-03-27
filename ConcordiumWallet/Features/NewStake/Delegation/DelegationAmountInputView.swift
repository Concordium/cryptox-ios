//
//  DelegationAmountInputView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 11.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct DelegationAmountInputView: View {
    
    @ObservedObject var viewModel: DelegationAmountInputViewModel
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .bottom) {
                DecimalNumberTextField(decimalValue: $viewModel.amountDecimal, fraction: $viewModel.fraction)
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
                    .frame(alignment: .leading)
            }
            
            SendTokenCell(tokenType: .ccd(displayAmount: GTU(intValue: viewModel.account.forecastBalance).displayValueWithTwoNumbersAfterDecimalPoint()),
                          hideCaretRight: true, text: "available.for.staking".localized)
            .frame(maxWidth: .infinity, alignment: .center)

            if let poolLimit = viewModel.poolLimit, let currentPoolLimit = viewModel.currentPoolLimit, viewModel.showsPoolLimits {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentPoolLimit.label)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(currentPoolLimit.value)
                        .font(.satoshi(size: 15, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(poolLimit.label)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(poolLimit.value)
                        .font(.satoshi(size: 15, weight: .bold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)
                }
            }
            
            HStack {
                Text(viewModel.stakingMode?.rawValue ?? "delegation.staking.mode".localized)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.stakingMode?.rawValue != nil ? .white : Color.MineralBlue.blueish3.opacity(0.5))
                    .frame(alignment: .leading)
                Spacer()
                Image("caretRight")
                    .renderingMode(.template)
                    .foregroundStyle(.grey4)
                    .frame(width: 30, height: 40)
            }
            .padding(.trailing, 8)
            .padding(.vertical, 18)
            .padding(.leading, 18)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)
            .onTapGesture {
                viewModel.stakingModeSelected()
            }
            
            if viewModel.stakingMode == nil {
                HStack(spacing: 8) {
                    Image("ico_info")
                    Text("staking.mode.nil".localized)
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                }
            }
            
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
        .modifier(AlertModifier(alertOptions: viewModel.alertOptions, isPresenting: $viewModel.showAlert))
    }
}
