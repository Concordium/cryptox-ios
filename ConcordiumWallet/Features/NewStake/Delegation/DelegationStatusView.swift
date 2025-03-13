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
            ButtonsGroup(actionItems: viewModel.actionItems())
            StakeDetailsView(rows: viewModel.rows)
            cooldownsSectionView
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
}

