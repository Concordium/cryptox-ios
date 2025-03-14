//
//  AccountsOverviewView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 07.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Foundation

struct AccountsOverviewView: View {
    
    @Binding var path: [NavigationPaths]
    @StateObject var viewModel: AccountsMainViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss
    weak var router: AccountsMainViewDelegate?
    private let dotImages = ["Dot1", "dot2", "dot3", "dot4", "dot5", "dot6", "dot7", "dot8", "dot9"]
    @State private var createAccountPressed: Bool = false
    @State private var selectedAccountAddress: String?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.accountViewModels, id: \.id) { account in
                    Button {
                        selectedAccountAddress = account.address
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            selectedAccountAddress = nil
                            viewModel.changeCurrentAccount(account)
                            dismiss()
                        }
                    } label: {
                        accountsView(account)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 18)
        }
        .safeAreaInset(edge: .bottom, content: {
            Button {
                router?.showCreateAccountFlow()
            } label: {
                Text("Create new account")
                    .font(.satoshi(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PressedButtonStyle())
            .padding(.horizontal, 18)
        })
        .modifier(NavigationViewModifier(title: "Your accounts", backAction: {
            dismiss()
        }, trailingAction: {
            if let selectedAccount = viewModel.selectedAccount?.account {
                router?.showSettings(selectedAccount)
            }
        }, trailingIcon: Image("settingsGear"), iconSize: CGSize(width: 20, height: 20)))
        .modifier(AppBackgroundModifier())
    }
    
    func accountsView(_ account: AccountPreviewViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 5) {
                    Image(account.dotImageIndex == 1 ? "Dot1" : "dot\(account.dotImageIndex)")
                        .frame(width: 12, height: 12)
                    Text(account.accountName)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundStyle(.whiteMain)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(account.totalAmount.displayValueWithTwoNumbersAfterDecimalPoint())
                        .font(.satoshi(size: 15, weight: .medium))
                    Image("Blockchain")
                        .resizable()
                        .frame(width: 10, height: 15)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("·")
                            .font(.satoshi(size: 15, weight: .medium))
                            .frame(width: 4, height: 15, alignment: .topLeading)
                        Text(account.stakedAmount.displayValueWithTwoNumbersAfterDecimalPoint())
                            .font(.satoshi(size: 15, weight: .medium))
                        Image("Blockchain")
                            .resizable()
                            .frame(width: 10, height: 15)
                    }
                    .opacity(account.stakedAmount > 0 ? 1 : 0)
                }
                .foregroundColor(.MineralBlue.blueish3)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 15) {
                Text(account.accountOwner)
                    .font(.satoshi(size: 15, weight: .medium))
                Text("% Earning")
                    .font(.satoshi(size: 15, weight: .medium))
                    .opacity(account.viewState == .delegating || account.viewState == .baking ? 1 : 0)
            }
            .foregroundColor(.MineralBlue.blueish3)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(selectedAccountAddress == account.address ? .selectedCell : .grey3.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color.MineralBlue.blueish3, lineWidth: 1)
                .opacity(account.account?.address == viewModel.selectedAccount?.address ? 1 : 0)
        )
        .overlay(alignment: .topLeading) {
            if (account.account?.baker?.isSuspended == true || account.account?.delegation?.isSuspended == true) || (account.account?.baker?.isPrimedForSuspension == true || account.account?.delegation?.isPrimedForSuspension == true) {
                Circle().fill(.attentionRed)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: 8)
            }
        }
    }
}
