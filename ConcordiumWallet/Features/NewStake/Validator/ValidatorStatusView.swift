//
//  ValidatorStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorStatusView: View {
    @ObservedObject var viewModel: ValidatorStakeStatusViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var updateTimer: Timer?
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isRegistered {
                if viewModel.isSuspended || viewModel.isPrimedForSuspension {
                    suspendedStatusView()
                }
                ButtonsGroup(actionItems: viewModel.actionItems())
                StakeDetailsView(rows: viewModel.rows)
                cooldownsSectionView
            } else {
                HStack(spacing: 8) {
                    Text(viewModel.topText)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Image(viewModel.topImageName)
                }
            }
            Spacer()
        }
        .onAppear(perform: startUpdateTimer)
        .onDisappear(perform: stopUpdateTimer)
        .alert(item: $viewModel.error, content: alert)
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
        .modifier(AlertModifier(alertOptions: viewModel.alertOptions ?? SwiftUIAlertOptions(title: nil, message: nil, actions: []), isPresenting: $viewModel.showAlert))    }
    
    private var cooldownsSectionView: some View {
        Group {
            if !viewModel.accountCooldowns.isEmpty {
                ForEach(viewModel.accountCooldowns) { cooldown in
                    CooldownCardView(cooldown: cooldown)
                }
            }
        }
    }
}

extension ValidatorStatusView {
    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            viewModel.updateStatus()
        }
    }
    
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func alert(for error: StakeStatusViewModelError) -> Alert {
        Alert(
            title: Text("errorAlert.title".localized),
            message: Text(ErrorMapper.toViewError(error: error.error).localizedDescription),
            dismissButton: .default(Text("errorAlert.okButton".localized))
        )
    }
    
    func suspendedStatusView() -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(viewModel.isSuspended ? "validation.status.suspended.title".localized : "validation.status.primed.for.suspension.title".localized)
                .font(.satoshi(size: 16, weight: .bold))
                .foregroundStyle(.attentionRed)
            Text(viewModel.isSuspended ? "validation.status.suspended.desc".localized : "validation.status.primed.for.suspension.desc")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
        }
        .padding([.leading, .top], 14)
        .padding(.trailing, 26)
        .padding(.bottom, 31)
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
    }
}
