//
//  TokenBalanceView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 08.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

struct TokenBalanceView: View {
    
    var token: AccountDetailAccount
    @Binding var path: [AccountNavigationPaths]
    var selectedAccount: AccountDataType
    @ObservedObject var viewModel: AccountDetailViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State var onRampFlowShown = false
    @State var accountQr: AccountEntity?
    weak var router: AccountsMainViewDelegate?
    @State private var isPresentingAlert = false
    @State private var showRawMdPopup = false

    var actionItems: [ActionItem]  {
        return accountActionItems()
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    balanceSection()
                        .padding(.horizontal, 18)
                    accountActionButtonsSection()
                    TokenDetailsView(token: token, showRawMd: $showRawMdPopup)
                    if token.name != "ccd" {
                        HStack(spacing: 8) {
                            Image("eyeSlash")
                            Text("Hide token from account")
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(.attentionRed)
                        }
                        .onTapGesture {
                            isPresentingAlert = true
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.vertical, 20)
            }
            if isPresentingAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
                if let cis2Token = token.cis2Token {
                    HideTokenPopup(
                        tokenName: cis2Token.metadata.name ?? "",
                        isPresentingAlert: $isPresentingAlert
                    ) {
                        viewModel.removeToken(cis2Token)
                        dismiss()
                    }
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
                }
            }
            
            if showRawMdPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
                
                rawMetadataView()
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: isPresentingAlert)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(NavigationViewModifier(title: "Balance") {
            dismiss()
        })
        .sheet(isPresented: $onRampFlowShown) {
            CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
        }
        .sheet(item: $accountQr) { account in
            AccountQRView(account: account)
        }
        .modifier(AppBackgroundModifier())
    }
    
    func balanceSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            
            switch token {
            case .ccd(let amount):
                Text("\(amount.displayValue()) CCD")
                    .font(.plexSans(size: 55, weight: .bold))
                    .dynamicTypeSize(.xSmall ... .xxLarge)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(RadialGradientForegroundStyleModifier())
                VStack(spacing: 4) {
                    if viewModel.hasStaked {
                        HStack {
                            Text("At disposal")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                            Spacer()
                            Text("\(viewModel.atDisposal?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00") CCD")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if let value = viewModel.totalCooldown, value.intValue > 0 {
                        HStack {
                            Text("Cooldown")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                            Spacer()
                            Text("\(value.displayValueWithTwoNumbersAfterDecimalPoint()) CCD")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if viewModel.hasStaked, let stakedValue = viewModel.stakedValue {
                        HStack {
                            Text("Earning")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish2)
                            Spacer()
                            Text("\(stakedValue.displayValueWithTwoNumbersAfterDecimalPoint()) CCD")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            case .token(let token, let amount) :
                Text(TokenFormatter()
                    .string(from: BigDecimal(BigInt(stringLiteral: amount), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ",") + " \(token.metadata.symbol ?? "")")
                .font(.plexSans(size: 55, weight: .bold))
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(RadialGradientForegroundStyleModifier())
            }
        }
    }
    
    func accountActionButtonsSection() -> some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                if index < actionItems.count {
                    VStack {
                        Image(actionItems[index].iconName)
                            .frame(width: 24, height: 24)
                            .padding(11)
                            .background(Color.grey3)
                            .foregroundColor(Color.MineralBlue.blueish3)
                            .cornerRadius(50)
                        Text(actionItems[index].label)
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundColor(Color.MineralBlue.blueish2)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        actionItems[index].action()
                    }
                } else {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    func rawMetadataView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Spacer()
                
                Image("close_icon")
                    .renderingMode(.template)
                    .foregroundStyle(.grey1)
                    .onTapGesture {
                        showRawMdPopup = false
                    }
            }
            Text(token.cis2Token?.metadata.toString() ?? "")
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.grey1)
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .frame(width: 327, alignment: .top)
        .modifier(FloatingGradientBGStyleModifier())
        .cornerRadius(16)
    }
    
    private func accountActionItems() -> [ActionItem] {
        var actionItems = [
            ActionItem(iconName: "buy", label: "Buy", action: {
                onRampFlowShown.toggle()
            }),
            ActionItem(iconName: "send", label: "Send", action: {
                guard let account = viewModel.account else { return }
                router?.showSendFundsFlow(account)
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                accountQr = (viewModel.account as? AccountEntity)
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                path.append(.activity)
            })
        ]
        if token.name == "ccd" {
            let earnAction = ActionItem(iconName: "Percent", label: "Earn", action: {
                router?.showEarnFlow(selectedAccount)
            })
            actionItems.insert(earnAction, at: 3)
        }
        return actionItems
    }
}
