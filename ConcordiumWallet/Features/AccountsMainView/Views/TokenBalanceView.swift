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
    @ObservedObject var viewModel: AccountDetailViewModel2
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State var onRampFlowShown = false
    @State var accountQr: AccountEntity?
    weak var router: AccountsMainViewDelegate?

    // TODO: Add action
    var actionItems: [ActionItem]  {
        var actionItems = accountActionItems()
        if token.name == "ccd" {
            let earnAction = ActionItem(iconName: "percent", label: "Earn", action: {
                
            })
            actionItems.insert(earnAction, at: 3)
        }
        return actionItems
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    balanceSection()
                        .padding(.horizontal, 18)
                    accountActionButtonsSection()
                    tokenDescriptionSection()
                        .padding(.horizontal, 18)
                    manageTokenView()
                        .padding(.horizontal, 18)
                }
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("ico_back")
                            .resizable()
                            .foregroundColor(.greySecondary)
                            .frame(width: 32, height: 32)
                            .contentShape(.circle)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Balance")
                            .font(.satoshi(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .sheet(isPresented: $onRampFlowShown) {
                CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
            }
            .sheet(item: $accountQr) { account in
                AccountQRView(account: account)
            }
            .modifier(AppBackgroundModifier())
        }
    }
    
    func balanceSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            
            switch token {
            case .ccd(let amount):
                Text("\(amount) CCD")
                    .font(.plexSans(size: 55, weight: .medium))
                    .dynamicTypeSize(.xSmall ... .xxLarge)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(RadialGradientForegroundStyleModifier())
                VStack(spacing: 4) {
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
                    .font(.plexSans(size: 55, weight: .medium))
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

    func tokenDescriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch token {
            case .ccd(_):
                HStack(spacing: 8) {
                    Image("ccd")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("CCD token")
                        .font(.satoshi(size: 16, weight: .semibold))
                        .foregroundStyle(.whiteMain)
                }
                Text("Description")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                Text("CCD is the native token of the Concordium blockchain. Its main use cases are the payment of transaction fees, the payment for the execution of smart contracts, payments between users, payments for commercial transactions, staking, and the rewards offered to node operators. ")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.white.opacity(0.1))
                
                Text("Decimals")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                
                Text("0-6")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
            case .token(let token, _):
                HStack(spacing: 8) {
                    if let url = token.metadata.thumbnail?.url {
                        CryptoImage(url: url.toURL, size: .custom(width: 20, height: 20))
                            .aspectRatio(contentMode: .fit)
                    }
                    Text(token.metadata.name ?? "")
                        .font(.satoshi(size: 16, weight: .semibold))
                        .foregroundStyle(.whiteMain)
                }
                Text("Description")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                Text(token.metadata.description ?? "")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.white.opacity(0.1))
                
                Text("Decimals")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                
                Text(token.metadata.decimals?.string ?? "")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .background(.white.opacity(0.1))
                
                Text("Contract index, subindex")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                
                Text("\(token.contractAddress.index), \(token.contractAddress.subindex)")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
            }
        }
        .padding(16)
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
    }
    
    // TODO: Add actions
    func manageTokenView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("notebook")
                Text("Show raw metadata")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(.whiteMain)
            }
            if token.name != "ccd" {
                HStack(spacing: 8) {
                    Image("eyeSlash")
                    Text("Hide token from account")
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.attentionRed)
                }
            }
        }
        .padding(.top, 11)
    }
    
    // TODO: Add actions
    private func accountActionItems() -> [ActionItem] {
        let actionItems = [
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
                
            })
        ]
        return actionItems
    }
}
