//
//  StakeStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 26.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct StakeStatusView: View {
    @ObservedObject var viewModel: StakeStatusViewModel
    @State private var updateTimer: Timer?
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    topInfoView
                    rowsSectionView
                    cooldownsSectionView
                }
            }
            Spacer()
            actionButtonsView
        }
        .onAppear(perform: startUpdateTimer)
        .onDisappear(perform: stopUpdateTimer)
        .alert(item: $viewModel.error, content: alert)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .modifier(AppBackgroundModifier())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.closeButtonTapped()
                } label: {
                    Image("backButtonIcon")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }

            ToolbarItem(placement: .principal) {
                Text(viewModel.title)
                    .font(.satoshi(size: 17, weight: .medium))
                    .foregroundStyle(Color.white)
            }
        }
    }
}

// MARK: - View Components

extension StakeStatusView {
    
    // Top Info View
    private var topInfoView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.system(size: 18))
            
            Text(viewModel.topText)
                .font(.satoshi(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .cornerRadius(16)
    }
    
    // Rows Section View
    private var rowsSectionView: some View {
        Group {
            if !viewModel.rows.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.rows) { row in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(row.headerLabel)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text(row.valueLabel)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            if row != viewModel.rows.last {
                                Divider()
                                    .tint(Color.blackAditional)
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blackAditional, lineWidth: 1))
            }
        }
    }
    
    // Cooldowns Section View
    private var cooldownsSectionView: some View {
        Group {
            if !viewModel.accountCooldowns.isEmpty {
                ForEach(viewModel.accountCooldowns) { cooldown in
                    cooldownItemView(cooldown: cooldown)
                }
            }
        }
    }
    
    private func cooldownItemView(cooldown: AccountCooldown) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inactive Stake")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text("You don’t receive rewards from this part of stake now, this amount will be at disposal after cooldown period.")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(GTU(intValue: Int(cooldown.amount))?.displayValue() ?? "")
                    .font(.satoshi(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack {
                Text("Cooldown time:")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(calculateCooldownTime(from: cooldown.timestamp))")
                    .foregroundColor(.white)
                    .font(.satoshi(size: 14, weight: .bold))
                Text("days left")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.blackSecondary))
        .cornerRadius(16)
        .padding(.top, 10)
    }
    
    // Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 10) {
            if viewModel.stopButtonShown {
                Button(action: viewModel.pressedStopButton) {
                    Text(viewModel.stopButtonLabel)
                        .font(.satoshi(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 48)
                            .stroke(Color.white, lineWidth: 1))
                        .foregroundColor(Color.errorText)
                }
                .disabled(!viewModel.stopButtonEnabled)
            }
            Button(action: viewModel.pressedButton) {
                Text(viewModel.buttonLabel)
                    .font(.satoshi(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 48)
                        .foregroundColor(.white))
                    .foregroundColor(.black)
            }
            .disabled(!viewModel.updateButtonEnabled)
        }
    }
    
    // Alert View
    private func alert(for error: StakeStatusViewModelError) -> Alert {
        Alert(
            title: Text("errorAlert.title".localized),
            message: Text(ErrorMapper.toViewError(error: error.error).localizedDescription),
            dismissButton: .default(Text("errorAlert.okButton".localized))
        )
    }
}

// MARK: - Helper Methods

extension StakeStatusView {
    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            viewModel.updateStatus()
        }
    }
    
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func calculateCooldownTime(from timestamp: Int) -> Int {
        let millisecondsInADay: UInt64 = 1000 * 60 * 60 * 24
        let endDate = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let daysToEndCooldown = Int((endDate.millisecondsSince1970 - Date.now.millisecondsSince1970) / millisecondsInADay)
        return daysToEndCooldown == 0 ? 1 : daysToEndCooldown
    }
}
