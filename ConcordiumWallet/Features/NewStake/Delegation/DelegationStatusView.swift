//
//  DelegationStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct DelegationStatusView: View {
    @ObservedObject var viewModel: DelegationStatusViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var updateTimer: Timer?
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.hasUnfinishedTransactions {
                HStack(spacing: 8) {
                    Text(viewModel.topText)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Image(viewModel.topImageName)
                }
            } else {
                if viewModel.isSuspended || viewModel.isPrimedForSuspension {
                    suspendedStatusView()
                }
                ButtonsGroup(actionItems: viewModel.actionItems())
                StakeDetailsView(rows: viewModel.rows)
                cooldownsSectionView
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

extension DelegationStatusView {
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
            Text("delegation.suspended.title".localized)
                .font(.satoshi(size: 16, weight: .bold))
                .foregroundStyle(.attentionRed)
            Text("delegation.suspended.desc".localized)
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.leading, .top], 14)
        .padding(.trailing, 26)
        .padding(.bottom, 31)
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
    }
}

