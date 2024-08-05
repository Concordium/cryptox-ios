//
//  AccountsMainView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

protocol AccountsMainViewDelegate: class {
    func showSendFundsFlow(_ account: AccountDataType)
    func showAccountDetail(_ account: AccountDataType)
    func showCreateIdentityFlow()
    func showCreateAccountFlow()
    func showScanQRFlow()
    func showExportFlow()
    func showUnshieldAssetsFlow()
}

struct AccountsMainView: View {
    @StateObject var viewModel: AccountsMainViewModel
    @EnvironmentObject var updateTimer: UpdateTimer
    
    @State var accountQr: AccountEntity?
    @State var onRampFlowShown: Bool = false
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    
    weak var router: AccountsMainViewDelegate?
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("accounts.totalBalanceTitleLabel".localized)
                        .foregroundColor(Color.Neutral.tint2)
                        .font(.satoshi(size: 14, weight: .regular))
                    Text(viewModel.totalBalance.displayValue())
                        .foregroundColor(Color.Neutral.tint1)
                        .font(.satoshi(size: 28, weight: .medium))
                        .overlay(alignment: .bottomTrailing) {
                            Text("CCD")
                                .foregroundColor(Color.MineralBlue.tint1)
                                .font(.satoshi(size: 12, weight: .regular))
                                .offset(x: 26, y: -4)
                        }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("accounts.overview.totalatdisposal".localized)
                        .foregroundColor(Color.Neutral.tint2)
                        .font(.satoshi(size: 14, weight: .regular))
                    Text(viewModel.atDisposal.displayValue())
                        .foregroundColor(Color.Neutral.tint1)
                        .font(.satoshi(size: 28, weight: .medium))
                        .overlay(alignment: .bottomTrailing) {
                            Text("CCD")
                                .foregroundColor(Color.MineralBlue.tint1)
                                .font(.satoshi(size: 12, weight: .regular))
                                .offset(x: 26, y: -4)
                        }
                }
                
                if viewModel.staked != .zero {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("accounts.overview.staked".localized)
                            .foregroundColor(Color.Neutral.tint2)
                            .font(.satoshi(size: 14, weight: .regular))
                        Text(viewModel.staked.displayValue())
                            .foregroundColor(Color.Neutral.tint1)
                            .font(.satoshi(size: 28, weight: .medium))
                            .overlay(alignment: .bottomTrailing) {
                                Text("CCD")
                                    .foregroundColor(Color.MineralBlue.tint1)
                                    .font(.satoshi(size: 12, weight: .regular))
                                    .offset(x: 26, y: -4)
                            }
                    }
                }
                Divider()
            }
            .padding(16)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            
            switch viewModel.state {
            case .empty:
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .accounts:
                VStack(spacing: 8) {
                    OnRampAnchorView()
                        .onTapGesture {
                            onRampFlowShown.toggle()
                        }
                    
                    ForEach(viewModel.accountViewModels, id: \.id) { vm in
                        AccountPreviewView(
                            viewModel: vm,
                            onQrTap: { accountQr = (vm.account as? AccountEntity) },
                            onSendTap: { router?.showSendFundsFlow(vm.account) },
                            onShowPlusTap: { onRampFlowShown.toggle() }
                        )
                        .onTapGesture {
                            router?.showAccountDetail(vm.account)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .createAccount:
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            self.router?.showCreateAccountFlow()
                            Tracker.trackContentInteraction(name: "Home screen", interaction: .clicked, piece: "Create account")
                        } label: {
                            Text("accounts.createNewAccount".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.vertical, 12)
                        .background(.white)
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            case .createIdentity:
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            self.router?.showCreateIdentityFlow()
                        } label: {
                            Text("accounts.createNewIdentity".localized)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.vertical, 12)
                        .background(.white)
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            Color.clear.padding(.bottom, viewModel.isBackupAlertShown ? 48 : 0)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .clipped()
        .modifier(AppBackgroundModifier())
        .listSectionSeparator(.hidden)
        .listStyle(.plain)
        .refreshable { Task { await viewModel.reload() } }
        .onAppear { Task { await viewModel.reload() } }
        .navigationTitle("accounts".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    self.router?.showScanQRFlow()
                } label: {
                    Image("qr")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.router?.showCreateAccountFlow()
                } label: {
                    Image("add")
                }
            }
        }
        .sheet(item: $accountQr) { account in
            AccountQRView(account: account)
        }
        .overlay(alignment: .bottom) {
            if viewModel.isBackupAlertShown && !isUserMakeBackup {
                HStack {
                    Text("main_scren_backup_warning_legacy_acount".localized)
                        .foregroundColor(Color.black)
                        .font(.system(size: 14, weight: .medium))
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .clipped()
                .onTapGesture {
                    self.router?.showExportFlow()
                }
            }
        }
        .onAppear { updateTimer.start() }
        .onDisappear { updateTimer.stop() }
        .onReceive(updateTimer.tick) { _ in
            Task {
                await self.viewModel.reload()
            }
        }
        .overlay(alignment: .center) {
            if isShouldShowSunsetShieldingView {
                let action: () -> Void = {
                    isShouldShowSunsetShieldingView = false
                    router?.showUnshieldAssetsFlow()
                }
                GenericPopup(imageName: "unshield_popup_icon",
                             title: "Transaction Shielding is\ngoing away",
                             message: "We recommend that you unshield any\nShielded balance today.",
                             buttonTitles: ["Unshield assets"],
                             buttonActions: [action],
                             closeButtonAction: {
                    isShouldShowSunsetShieldingView = false
                })
            }
        }
        .sheet(isPresented: $onRampFlowShown, content: {
            CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
        })
        .onAppear { Tracker.track(view: ["Home screen"]) }
    }
    
    private func OnRampAnchorView() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                Image("onramp_flow_icon")
                VStack(alignment: .leading) {
                    Text("Where is CCD available?")
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.08))
                        .frame(alignment: .leading)
                    Group {
                        Text("CCD is listed in the following exchanges and services.")
                        + Text(" See more")
                            .underline()
                    }
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.3, green: 0.31, blue: 0.28))
                    .frame(alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(red: 1, green: 0.99, blue: 0.89))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.06, green: 0.08, blue: 0.08).opacity(0.05), lineWidth: 1)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
