//
//  DelegationStakingModeView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 11.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct DelegationStakingModeView: View {
    @FocusState private var isValidatorPoolIdFocused: Bool
    @ObservedObject var viewModel: DelegationStakingModeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("delegation.staking.desc".localized)
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundStyle(Color.MineralBlue.blueish2)
                .padding(.horizontal, 15)
            VStack(spacing: 4) {
                stakingOption(title: "delegation.staking.mode.passive".localized, isSelected: Binding(
                    get: { viewModel.selectedPool == .passive },
                    set: { isSelected in
                        viewModel.selectedPool = isSelected ? .passive : .validatorPool
                    }
                ))
                stakingOption(title: "delegation.staking.mode.validator.pool".localized, isSelected: Binding(
                    get: { viewModel.selectedPool == .validatorPool },
                    set: { isSelected in
                        viewModel.selectedPool = isSelected ? .validatorPool : .passive
                    }
                ))
            }
            
            if viewModel.selectedPool == .validatorPool {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("delegation.validator.pool.id".localized)
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3)
                            .opacity(0.5)
                            .multilineTextAlignment(.leading)
                            .animation(.easeInOut, value: viewModel.selectedPool == .validatorPool)
                        TextField("", text: $viewModel.validatorId)
                            .foregroundColor(.white)
                            .tint(.white)
                            .focused($isValidatorPoolIdFocused)
                            .font(.system(size: 16))
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.validatorId) { value in
                            }
                            .animation(.easeInOut, value: viewModel.selectedPool == .validatorPool)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isValidatorPoolIdFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                        .background(.clear)
                        .cornerRadius(12)
                )
                
                if let error = viewModel.validatorIdErrorMessage {
                    Text(error)
                        .foregroundColor(Color(hex: 0xFF163D))
                        .font(.satoshi(size: 15, weight: .medium))
                        .frame(alignment: .leading)
                }
                
                Text("delegation.staking.mode.validator.pool.desc".localized)
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundStyle(Color.MineralBlue.blueish2)
            }
            Spacer()
            RoundedButton(action: {
                viewModel.pressedContinue()
            }, title: "continue_btn_title".localized, isDisabled: !viewModel.isContinueEnabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
        .padding(.horizontal, 18)
        .modifier(AppBackgroundModifier())
    }
    
    func stakingOption(title: String, isSelected: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.satoshi(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.leading, 6)
            Spacer()
            RoundedSquareView(needToFill: isSelected)
                .onTapGesture {
                    withAnimation {
                        isSelected.wrappedValue.toggle()
                    }
                }
                .frame(width: 24, height: 24)
        }
        .padding(12)
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
    }
}
