//
//  AccountsMainView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

protocol AccountsMainViewDelegate: AnyObject {
    func showSendFundsFlow(_ account: AccountDataType)
    func showAccountDetail(_ account: AccountDataType)
    func showCreateIdentityFlow()
    func showSaveSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void)
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
    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    @State var phrase: [String]?
    @State var isShowPasscodeViewShown: Bool = false
    @SwiftUI.Environment(\.dismiss) var dismiss
        
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    
    var hasShieldedBalances: Bool {
        viewModel.accounts.compactMap(\.hasShieldedTransactions).reduce(false, { $0 || $1 })
    }
    
    weak var router: AccountsMainViewDelegate?
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("accounts.totalBalanceTitleLabel".localized)
                        .foregroundColor(Color.MineralBlue.tint1)
                        .font(.satoshi(size: 14, weight: .regular))
                    Text(viewModel.totalBalance.displayValue())
                        .foregroundColor(Color.MineralBlue.tint1)
                        .font(.satoshi(size: 28, weight: .medium))
                        .overlay(alignment: .bottomTrailing) {
                            Text("CCD")
                                .foregroundColor(Color.MineralBlue.tint1)
                                .font(.satoshi(size: 12, weight: .regular))
                                .offset(x: 26, y: -4)
                        }
                    
                    Text("\(viewModel.atDisposal.displayValue()) at disposal")
                        .foregroundColor(Color.MineralBlue.tint1)
                        .font(.satoshi(size: 14, weight: .medium))
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
            Spacer()
            
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
                List {
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
                }
                .listSectionSeparator(.hidden)
                .listStyle(.plain)
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
                    AccountCreationProgressView(targetProgress: 2 / 3, stepName: "final_step_verify_identity".localized)
                    
                    Spacer()
                    
                    Button(
                        action: {
                            self.router?.showCreateIdentityFlow()
                        }, label: {
                            HStack {
                                Text("create_wallet_step_3_title".localized)
                                    .font(Font.satoshi(size: 16, weight: .medium))
                                    .lineSpacing(24)
                                    .foregroundColor(Color.Neutral.tint7)
                                Spacer()
                                Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                            }
                            .padding(.horizontal, 24)
                        })
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                }
                
            case .saveSeedPhrase:
                VStack {
                    AccountCreationProgressView(targetProgress: 1 / 3, stepName: "next_step_seed_phrase".localized)
                    Spacer()
                    Button(
                        action: {
                            isShowPasscodeViewShown = true
                        }, label: {
                            HStack {
                                Text("create_wallet_step_2_title".localized)
                                    .font(Font.satoshi(size: 16, weight: .medium))
                                    .lineSpacing(24)
                                    .foregroundColor(Color.Neutral.tint7)
                                Spacer()
                                Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                            }
                            .padding(.horizontal, 24)
                        })
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                }
                
            case .identityVerification:
                EmptyView()
            }
        }
        .padding(17)
        .modifier(AppBlackBackgroundModifier())
        .refreshable { Task { await viewModel.reload() } }
        .onAppear { Task { await viewModel.reload() } }
        .navigationTitle("accounts".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    self.router?.showScanQRFlow()
                } label: {
                    Image("qr")
                        .frame(width: 32, height: 32)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.router?.showCreateAccountFlow()
                } label: {
                    Image("ico_add")
                        .frame(width: 32, height: 32)
                }
            }
        }
        .sheet(item: $accountQr) { account in
            AccountQRView(account: account)
        }
//        .overlay(alignment: .bottom) {
//            if viewModel.isBackupAlertShown && !isUserMakeBackup {
//                HStack {
//                    Text("main_scren_backup_warning_legacy_acount".localized)
//                        .foregroundColor(Color.black)
//                        .font(.system(size: 14, weight: .medium))
//                        .padding()
//                }
//                .frame(maxWidth: .infinity)
//                .background(Color.yellow)
//                .clipped()
//                .onTapGesture {
//                    self.router?.showExportFlow()
//                }
//            }
//        }
        .onAppear { updateTimer.start() }
        .onDisappear { updateTimer.stop() }
        .onReceive(updateTimer.tick) { _ in
            Task {
                await self.viewModel.reload()
            }
        }
        .overlay(alignment: .center) {
            if isShouldShowSunsetShieldingView && hasShieldedBalances {
                PopupContainer(icon: "unshield_popup_icon",
                               title: "Transaction Shielding is\ngoing away",
                               subtitle: "We recommend that you unshield any\nShielded balance today.",
                               content: unshieldAssetsButtonView(),
                               dismissAction: {
                    isShouldShowSunsetShieldingView = false
                })
            }
        }
        .sheet(isPresented: $onRampFlowShown, content: {
            CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
        })
        .onAppear { Tracker.track(view: ["Home screen"]) }
        .fullScreenCover(isPresented: $isShowPasscodeViewShown, content: {
            PasscodeView(keychain: keychain,
                         sanityChecker: SanityChecker(mobileWallet: ServicesProvider.defaultProvider().mobileWallet(),
                                                      storageManager: ServicesProvider.defaultProvider().storageManager())) { pwHash in
                isShowPasscodeViewShown = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.router?.showSaveSeedPhraseFlow(pwHash: pwHash, identitiesService: identitiesService, completion: { phrase in
                        if identitiesService.mobileWallet.hasSetupRecoveryPhrase  {
                            self.phrase = phrase
                            Task { await viewModel.reload() }
                        }
                    })
                }
            }
        })
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
    
    private func unshieldAssetsButtonView() -> some View {
        Button(action: {
            isShouldShowSunsetShieldingView = false
            router?.showUnshieldAssetsFlow()
        }, label: {
            Text("Unshield assets")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                .cornerRadius(21)
        })
    }
}
