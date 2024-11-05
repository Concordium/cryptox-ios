//
//  AccountsMainView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import DotLottie

protocol AccountsMainViewDelegate: AnyObject {
    func showSendFundsFlow(_ account: AccountDataType)
    func showAccountDetail(_ account: AccountDataType)
    func showCreateIdentityFlow()
    func showSaveSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void)
    func showCreateAccountFlow()
    func showScanQRFlow()
    func showExportFlow()
    func showUnshieldAssetsFlow()
    func showNotConfiguredAccountPopup()
}

struct AccountsMainView: View {
    @StateObject var viewModel: AccountsMainViewModel
    @EnvironmentObject var updateTimer: UpdateTimer
    
    @State var accountQr: AccountEntity?
    @State var onRampFlowShown = false
    @State var phrase: [String]?
    @State var isShowPasscodeViewShown = false
    @State private var previousState: AccountsMainViewState?
    @State private var selectedPage = 0
    @State private var showAnimation = true
    @State private var createAccountHeight: CGFloat?
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    
    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    weak var router: AccountsMainViewDelegate?
    
    private var hasShieldedBalances: Bool {
        viewModel.accounts.compactMap(\.hasShieldedTransactions).reduce(false, { $0 || $1 })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.state == .accounts {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        acocuntViewContent()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 32) {
                    acocuntViewContent()
                }
            }
        }
        .modifier(AppBlackBackgroundModifier())
        .refreshable { Task { await viewModel.reload() } }
        .onAppear { Task { await viewModel.reload() } }
        .navigationTitle("accounts".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if SettingsHelper.isIdentityConfigured() {
                        self.router?.showScanQRFlow()
                    } else {
                        self.router?.showNotConfiguredAccountPopup()
                    }
                } label: {
                    Image("qr")
                        .frame(width: 32, height: 32)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if SettingsHelper.isIdentityConfigured() {
                        self.router?.showCreateAccountFlow()
                    } else {
                        self.router?.showNotConfiguredAccountPopup()
                    }
                } label: {
                    Image("ico_add")
                        .frame(width: 32, height: 32)
                }
            }
        }
        .sheet(item: $accountQr) { account in
            AccountQRView(account: account)
        }
        .onAppear { updateTimer.start() }
        .onDisappear { updateTimer.stop() }
        .onReceive(updateTimer.tick) { _ in
            Task {
                await self.viewModel.reload()
            }
        }
        .overlay(content: {
            if viewModel.state == .accounts && previousState == .createAccount && showAnimation {
                DotLottieAnimation(fileName: "confettiAnimation", config: AnimationConfig(autoplay: true, loop: false)).view()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showAnimation = false
                        }
                    }
            }
        })
        .overlay(alignment: .center) {
            if isShouldShowSunsetShieldingView && hasShieldedBalances {
                PopupContainer(
                    icon: "unshield_popup_icon",
                    title: "Transaction Shielding is\ngoing away",
                    subtitle: "We recommend that you unshield any\nShielded balance today.",
                    content: unshieldAssetsButtonView(),
                    dismissAction: {
                        isShouldShowSunsetShieldingView = false
                    }
                )
            }
        }
        .sheet(isPresented: $onRampFlowShown) {
            CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
        }
        .fullScreenCover(isPresented: $isShowPasscodeViewShown, content: {
            passcodeView
        })
        .onAppear { Tracker.track(view: ["Home screen"]) }
        .onChange(of: viewModel.state) { newState in
            if newState != .accounts {
                previousState = newState
            }
        }
    }
}

extension AccountsMainView {
    // MARK: - Account Balances Section
    private var accountBalancesSection: some View {
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
        }
        .background(.clear)
    }
    
    private func disposalText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(Color.MineralBlue.tint1)
            .font(.satoshi(size: 14, weight: .medium))
    }
    
    private func acocuntViewContent() -> some View {
        VStack(alignment: .leading) {
            accountBalancesSection
                .padding(16)
            
            Divider()
            NewsPageView(selectedTab: $selectedPage, views: {
                [
                    AnyView(OnRampAnchorView()
                        .onTapGesture {
                            if !SettingsHelper.isIdentityConfigured() {
                                self.router?.showNotConfiguredAccountPopup()
                            } else {
                                onRampFlowShown.toggle()
                            }
                        })
                ]
            })
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .padding(.top, 32)
            contentViewBasedOnState
                .padding(.horizontal, 16)
                .padding(.vertical)
                .background(Color.clear)
        }
    }
    
    // MARK: - Content Based on ViewModel State
    @ViewBuilder
    private var contentViewBasedOnState: some View {
        switch viewModel.state {
        case .empty:
            VStack {
                Spacer()
                EmptyView()
                Spacer()
            }
            
        case .accounts:
            VStack(spacing: 15) {
                ForEach(viewModel.accountViewModels, id: \.id) { vm in
                    
                    AccountPreviewCardView(
                        state: .accounts,
                        viewModel: vm,
                        onQrTap: { accountQr = (vm.account as? AccountEntity) },
                        onSendTap: { router?.showSendFundsFlow(vm.account) },
                        onShowPlusTap: { onRampFlowShown.toggle() }
                    )
                    .frame(height: createAccountHeight)
                    .onTapGesture {
                        router?.showAccountDetail(vm.account)
                    }
                }
            }
            .transition(.opacity)
            
        case .createAccount:
            VStack {
                AccountPreviewCardView(onCreateAccount: { self.router?.showCreateAccountFlow() }, state: .createAccount)
                    .background(
                        GeometryReader { innerGeometry in
                            Color.clear.onAppear {
                                // Capture the height for both states
                                    createAccountHeight = innerGeometry.size.height
                            }
                        }
                    )
                    .frame(height: createAccountHeight)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .transition(.opacity)
            
        case .createIdentity:
            VStack {
                AccountPreviewCardView(state: .createIdentity)
                        .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: {
                    self.router?.showCreateIdentityFlow()
                }, label: {
                    HStack {
                        Text("create_wallet_step_3_title".localized)
                            .font(Font.satoshi(size: 16, weight: .medium))
                            .foregroundColor(Color.Neutral.tint7)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28)
                })
                .padding(.bottom, 23)
            }
            .transition(.opacity)

        case .identityVerification:
            VStack {
                AccountPreviewCardView(state: .identityVerification)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .transition(.opacity)

        case .verificationFailed:
            VStack {
                AccountPreviewCardView(onIdentityVerification: { self.router?.showCreateIdentityFlow() }, state: .verificationFailed)
                        .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .transition(.opacity)

        case .saveSeedPhrase:
            VStack {
                AccountPreviewCardView(state: .saveSeedPhrase)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    isShowPasscodeViewShown = true
                } label: {
                    HStack {
                        Text("create_wallet_step_2_title".localized)
                            .font(Font.satoshi(size: 16, weight: .medium))
                            .foregroundColor(Color.Neutral.tint7)
                        Spacer()
                        Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28)
                }
                .padding(.bottom, 23)
            }
            .transition(.opacity)
        }
    }
    
    // MARK: - Passcode View
    private var passcodeView: some View {
        PasscodeView(keychain: keychain,
                     sanityChecker: SanityChecker(mobileWallet: ServicesProvider.defaultProvider().mobileWallet(),
                                                  storageManager: ServicesProvider.defaultProvider().storageManager())) { pwHash in
            isShowPasscodeViewShown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.router?.showSaveSeedPhraseFlow(pwHash: pwHash, identitiesService: identitiesService) { phrase in
                    if identitiesService.mobileWallet.hasSetupRecoveryPhrase {
                        self.phrase = phrase
                        Task { await viewModel.reload() }
                    }
                }
            }
        }
    }
    
    // MARK: - OnRamp Anchor View
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(Color.whiteMain)
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
