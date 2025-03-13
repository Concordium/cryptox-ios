//
//  DelegationSubmissionView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

struct DelegationSubmissionView: View {
    @ObservedObject var viewModel: DelegationSubmissionViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack(alignment: .center) {
            GeometryReader { geometry in
                if viewModel.isStopDelegation {
                    specialStatesValidationSection()
                } else {
                    VStack(alignment: .center, spacing: 24) {
                        VStack(alignment: .center, spacing: 10) {
                            Text(viewModel.account.displayName)
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            Image("ArrowRight")
                                .rotationEffect(.degrees(90))
                            if let mode = viewModel.stakingMode {
                                Text(mode.rawValue)
                                    .font(.satoshi(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                        Divider()
                        
                        VStack(spacing: 8) {
                            Text("Amount(\(viewModel.ticker)):")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                            Text(viewModel.amountDisplay)
                                .font(.plexSans(size: 40, weight: .medium))
                                .dynamicTypeSize(.small ... .xxLarge)
                                .minimumScaleFactor(0.3)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .modifier(RadialGradientForegroundStyleModifier())
                            Text(String(format: "transaction.fee".localized, viewModel.transactionFeeText))
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(.grey4)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .center, spacing: 8) {
                            Text("stake.receipt.restake".localized)
                                .font(.satoshi(size: 12, weight: .regular))
                                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                            Text(viewModel.restakeText)
                                .font(.satoshi(size: 12, weight: .regular))
                                .foregroundStyle(.white)
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
                }
            }
            Spacer()

            SliderButton(text: viewModel.sliderButtonText) {
                navigationManager.navigate(to: .delegationTransactionStatus(viewModel))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
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
    
    private func specialStatesValidationSection() -> some View {
        VStack(alignment: .center, spacing: 30) {
            Text(viewModel.submitTransactionDetailsSection.title)
                .font(.satoshi(size: 15, weight: .medium))
                .foregroundStyle(.white)
            VStack(spacing: 8) {
                if let subtitle = viewModel.submitTransactionDetailsSection.subtitle {
                    Text(subtitle)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundStyle(.white)
                }
                Text(String(format: "transaction.fee".localized, viewModel.transactionFeeText))
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundStyle(.grey4)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.grey4.opacity(0.3), lineWidth: 1)
        )
    }
}
