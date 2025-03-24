//
//  ComissionSettingsView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ComissionSettingsView: View {
    @StateObject var viewModel: ValidatorCommissionSettingsViewModel
    let sliderStep = 1e-5
    let formatter: NumberFormatter = .commissionFormatter
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        VStack {
            if let ranges = viewModel.commissionRanges {
                VStack(alignment: .leading, spacing: 12) {
                    Text("validator.comissions.desc".localized)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                    
                    comissionSettingsBlock(title: "validator.transaction.commission".localized, commission: $viewModel.transactionFeeCommission, range: ranges.transactionCommissionRange.min...ranges.transactionCommissionRange.max)
                    comissionSettingsBlock(title: "validator.reward.commission".localized, commission: $viewModel.bakingRewardCommission, range: ranges.bakingCommissionRange.min...ranges.bakingCommissionRange.max)
                        .padding(.top, 24)
                    Spacer()
                    RoundedButton(action: {
                        viewModel.continueButtonTapped {
                            navigationManager.navigate(to: .metadataUrl(ValidatorMetadataViewModel(dataHandler: viewModel.handler,
                                                                                                   navigationManager: navigationManager)))
                        }
                    }, title: "continue_btn_title".localized)
                }
            }
            else {
                Spacer()
                LoadingIndicator()
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(
            "Error",
            isPresented: $viewModel.error.isNotNil(),
            presenting: viewModel.error,
            actions: { error in
                Button {
                    switch error {
                    case .networkError:
                        navigationManager.pop()
                    default: break
                    }
                    viewModel.error = nil
                } label: {
                    Text("OK")
                }
            },
            message: { error in
                Text(error.errorMessage)
            }
        )
        .modifier(AppBackgroundModifier())
    }
    
    private func comissionSettingsBlock(title: String, commission: Binding<Double>, range: ClosedRange<Double>) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .padding(.horizontal, 14)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3)

                Text("\(formatter.string(from: NSNumber(value: commission.wrappedValue))!)%")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            .background(Color.grey3.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.grey4.opacity(0.3), lineWidth: 1)
            )
            .overlay(alignment: .bottom) {
                GeometryReader { geometry in
                    let sliderPadding: CGFloat = 30
                    let sliderWidth = geometry.size.width - sliderPadding
                    let normalizedValue = (commission.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                    let xOffset = normalizedValue * sliderWidth - (sliderWidth / 2)
                    
                    // Overlay the slider on the bottom border
                    
                    
                    ZStack {
                        // Overlay the slider on the bottom border
                        Slider(value: commission, in: range, step: sliderStep)
                            .accentColor(.white)
                            .tint(.success)
                            .offset(y: 13)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: commission.wrappedValue) { newValue in
                                let roundedValue = (newValue * 100_000).rounded() / 100_000
                                commission.wrappedValue = roundedValue
                            }

                        // White circle that moves with the slider
                        Circle()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .offset(x: xOffset, y: 13)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 30)
            }
    }
}
