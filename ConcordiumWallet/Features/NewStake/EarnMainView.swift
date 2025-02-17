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
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack(alignment: .center, spacing: 40) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 0) {
                        Text("earn.info.title.part1".localized + " ")
                            .font(.satoshi(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                        Text(
                            String(format: "earn.info.title.part2".localized, "4-6%"))
                        .font(.satoshi(size: 16, weight: .heavy))
                        .foregroundStyle(.success)
                        Text("earn.info.title.part3".localized)
                            .font(.satoshi(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                    }

                    descView()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
                .padding(.horizontal, 18)
                .background(.grey2.opacity(0.3))
                .cornerRadius(12)

            Button {
                // TODO: become a validator
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
            
            Spacer()
            
            VStack(spacing: 8) {
                Button {
//                    navigationManager.navigate(to: .earnInputMode(StakeAmountInputViewModel2(account: account, dataHandler: StakeDataHandler(transferType: .registerDelegation), dependencyProvider: ServicesProvider.defaultProvider())))
                } label: {
                    Text("earn.start".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle())

                Button {
                    // TODO: Start
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
                        .font(.satoshi(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                    Text("earn.info.part\(index).desc".localized)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                }
            }
        }
    }
}
