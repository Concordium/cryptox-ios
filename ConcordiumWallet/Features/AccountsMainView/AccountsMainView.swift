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
}

struct AccountsMainView: View {
    @StateObject var viewModel: AccountsMainViewModel
//    @EnvironmentObject var router: AccountsMainRouter
    @EnvironmentObject var updateTimer: UpdateTimer
    
    @State var accountQr: AccountEntity?
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    
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
//            .background(Color.blackSecondary)
//            .cornerRadius(24, corners: .allCorners)
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
                    ForEach(viewModel.accountViewModels, id: \.id) { vm in
                        AccountPreviewView(
                            viewModel: vm,
                            onQrTap: { accountQr = (vm.account as? AccountEntity) },
                            onSendTap: { router?.showSendFundsFlow(vm.account) }
                        )
                        .onTapGesture {
                            router?.showAccountDetail(vm.account)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                case .createAccount:
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                self.router?.showCreateAccountFlow()
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
    }
}
