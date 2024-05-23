//
//  ShieldedAccountsView.swift
//  CryptoX
//
//  Created by Max on 20.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ShieldedAccountsView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ShieldedAccountsViewModel
    @State var isPasscodeViewShow: Bool = false
    
    @State var unshieldFlowShown: AccountEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: UnshieldAssetsView(viewModel: .init(account: unshieldFlowShown, dependencyProvider: viewModel.dependencyProvider)),
                    isActive: Binding<Bool>(
                        get: { unshieldFlowShown != nil },
                        set: { _ in unshieldFlowShown = nil }
                    ),
                    label: { EmptyView() }
                )
                .hidden()
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
                .ignoresSafeArea(.all)
                
                switch viewModel.state {
                case .loadingInitial:
                    ProgressView()
                case .loaded(let accounts):
                    List(accounts) { data in
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(data.displayname)
                                    .font(.satoshi(size: 14, weight: .medium))
                                    .foregroundStyle(Color.blackAditional)
                                Text(data.balance.title)
                                    .font(.satoshi(size: 20, weight: .medium))
                                    .foregroundStyle(Color.white)
                            }
                            
                            Spacer()
                            switch data.balance {
                            case .decrypted:
                                UnshieldButton(data)
                            case .encrypted(let balance):
                                if balance.value == .zero {
                                    HStack {
                                        Text("Unshielded")
                                            .font(.satoshi(size: 15, weight: .medium))
                                            .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                                        Image(systemName: "checkmark")
                                            .renderingMode(.template)
                                            .foregroundStyle(Color(hex: 0x149E7E))
                                    }
                                } else {
                                    UnshieldButton(data)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 16)
                    }
                    .listStyle(.plain)
                case .noAccounts:
                    VStack(spacing: 24) {
                        Text("No Shielded Transactions")
                            .font(.satoshi(size: 20, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("ico_close")
                            .foregroundColor(Color.Neutral.tint1)
                            .frame(width: 35, height: 35)
                            .contentShape(.circle)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Accounts")
                            .font(.satoshi(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                        Text("with shielded assets")
                            .font(.satoshi(size: 11, weight: .medium))
                            .foregroundStyle(Color.blackAditional)
                    }
                }
            }
            .passcodeInput(isPresented: $isPasscodeViewShow) { seed in
                viewModel.decryptBalances(seed)
            }
            .onAppear {
                viewModel.reload()
            }
        }
    }
    
    func UnshieldButton(_ account: AccountViewData) -> some View {
        Button {
            Vibration.vibrate(with: .light)
            switch account.balance {
            case .decrypted:
                isPasscodeViewShow.toggle()
            case .encrypted:
                self.unshieldFlowShown = viewModel.getUnshieldAccount(account)
            }
        } label: {
            Text("Unshield")
                .font(.satoshi(size: 15, weight: .medium))
                .foregroundStyle(Color.black)
                .padding(.vertical, 13)
                .padding(.horizontal, 28)
                .contentShape(.rect)
        }
        .background(.white)
        .cornerRadius(48)
        .buttonStyle(.plain)
    }
}
