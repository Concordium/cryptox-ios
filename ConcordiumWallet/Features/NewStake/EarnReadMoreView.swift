//
//  EarnReadMoreView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum EarnMode {
    case validator
    case delegation
}

struct EarnReadMoreView: View {
    var mode: EarnMode
    var account: AccountDataType
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    switch mode {
                    case .delegation:
                        descriptionBlockView(title: "delegation.title".localized, description: "delegation.desc".localized)
                        descriptionBlockView(title: "staling.pools.title".localized, description: "staking.pools.desc".localized)
                        descriptionBlockView(title: "passive.delegation.title".localized, description: "passive.delegation.desc".localized)
                        descriptionBlockView(title: "pay.days.title".localized, description: "pay.days.desc".localized)
                        descriptionBlockView(title: "lockins.cooldowns.title".localized, description: "lockins.cooldowns.desc".localized)
                        descriptionBlockView(title: "status.page.title".localized, description: "status.page.desc".localized)
                    case .validator:
                        HStack(alignment: .top, spacing: 8) {
                            Image("info_gradient")
                                .renderingMode(.template)
                                .foregroundStyle(Color.Status.infoOrange)
                            Text("warning.earn.note".localized)
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                        }
                        .padding(.trailing, 10)
                        descriptionBlockView(title: "validator.start.title".localized, description: "validator.start.desc".localized)
                        descriptionBlockView(title: "validator.node.title".localized, description: "validator.node.desc".localized)
                        descriptionBlockView(title: "validator.opening.pool.title".localized, description: "validator.opening.pool.desc".localized)
                    }
                }
            }
            switch mode {
            case .validator:
                Button {
                    guard let account = account as? AccountEntity else { return }
                    let handler = BakerDataHandler(account: account, action: .register)
                    let viewModel = ValidatorAmountInputViewModel(
                            account: handler.account,
                            dependencyProvider: ServicesProvider.defaultProvider(),
                            dataHandler: handler,
                            navigationManager: navigationManager
                        )
                    navigationManager.navigate(to: .amountInput(viewModel))
                } label: {
                    Text("earn.start".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle())
            case .delegation:
                Button {
                    guard let account = account as? AccountEntity else { return }
                    let handler = DelegationDataHandler(account: account, isRemoving: false)
                    let viewModel = DelegationAmountInputViewModel(account: account,
                                                                   dataHandler: handler,
                                                                   navigationManager: navigationManager)
                    navigationManager.navigate(to: .delegationAmountInput(viewModel))
                } label: {
                    Text("earn.start".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    func descriptionBlockView(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.satoshi(size: 16, weight: .heavy))
                .foregroundStyle(.white)
            Text(description)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(red: 0.17, green: 0.19, blue: 0.2).opacity(0.3))
        .cornerRadius(12)
    }
}
