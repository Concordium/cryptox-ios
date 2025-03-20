//
//  ValidatorSubmissionView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorSubmissionView: View {
    @ObservedObject var viewModel: ValidatorSubmissionViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack {
            ScrollView {
                if viewModel.isStopValidation || viewModel.isSuspendValidation || viewModel.isResumeValidation {
                    specialStatesValidationSection()
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        if let text = viewModel.text {
                            Text(text)
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.rows, id: \.id) { row in
                                keySection(title: row.headerLabel, key: row.valueLabel)
                                if row.id != viewModel.rows.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding([.leading, .top], 14)
                        .padding(.trailing, 26)
                        .padding(.bottom, 18)
                        .background(.grey3.opacity(0.3))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                    }
                }
            }
            SliderButton(text: viewModel.sliderButtonText) {
                navigationManager.navigate(to: .validatorTransactionStatus(viewModel))
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
