//
//  EarnMainView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct EarnMainView: View {
    
    var account: AccountEntity
    @State private var validatorPressed: Bool = false
    @State private var startPressed: Bool = false
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 17) {
                            HStack(spacing: 0) {
                                Text("earn.info.title.part1".localized + " ")
                                    .font(.satoshi(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(
                                    String(format: "earn.info.title.part2".localized, "6%"))
                                .font(.satoshi(size: 24, weight: .bold))
                                .foregroundStyle(.success)
                            }
                            
                            descView()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 18)
                        .background(.grey2.opacity(0.3))
                        .cornerRadius(12)
                        
                        Text("apy.additional.info".localized)
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(Color.MineralBlue.blueish2.opacity(0.6))
                    }
                    Button {
                        validatorPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            validatorPressed = false
                            navigationManager.navigate(to: .earnReadMode(mode: .validator, account: account))
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("earn.become.validator".localized)
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(validatorPressed ? .buttonPressed : .white)
                            Image("ArrowRight")
                                .renderingMode(.template)
                                .foregroundStyle(validatorPressed ? .buttonPressed : .white)
                            Spacer()
                        }
                    }
                    .noStyle()
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                cooldownsSectionView
            }
            Spacer()
            
            VStack(spacing: 8) {
                Button {
                    startPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        navigationManager.navigate(to: .delegationAmountInput(DelegationAmountInputViewModel(account: account,
                                                                                                             dataHandler: DelegationDataHandler(account: account, isRemoving: false), navigationManager: navigationManager)))
                        validatorPressed = false
                    }
                } label: {
                    Text("earn.start".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle())
                
                Button {
                    navigationManager.navigate(to: .earnReadMode(mode: .delegation, account: account))
                } label: {
                    Text("read.more".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18.5)
                        .frame(maxWidth: .infinity)
                        .background(.grey5)
                        .cornerRadius(28)
                }
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    func descView() -> some View {
        ForEach(1..<4) { index in
            HStack(alignment: .top, spacing: 10) {
                    Image("icon_selection")
                VStack(alignment: .leading, spacing: 8) {
                    Text("earn.info.part\(index).title".localized)
                        .font(.satoshi(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("earn.info.part\(index).desc".localized)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var cooldownsSectionView: some View {
        Group {
            if !accountCooldowns.isEmpty {
                ForEach(accountCooldowns) { cooldown in
                    CooldownCardView(cooldown: cooldown)
                }
            }
        }
    }
    
    private var accountCooldowns: [AccountCooldown] {
        account.cooldowns.map({AccountCooldown(timestamp: $0.timestamp, amount: $0.amount, status: $0.status.rawValue)})
    }
}
