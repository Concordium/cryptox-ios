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
    func createAccountFromOnboarding(isCreatingAccount: Binding<Bool>)
    func showEarnFlow(_ account: AccountDataType)
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
    @State private var isCreatingAccount = false
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    @State private var hasShownAnimationKey = "showConfettiAnimation"
    
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
        .modifier(AppBackgroundModifier())
        .refreshable { Task { await viewModel.reload() } }
        .onAppear { Task { await viewModel.reload() } }
        .navigationTitle("accounts".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if SettingsHelper.isIdentityConfigured() {
                        self.router?.showScanQRFlow()
                        Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Scan QR")
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
                        Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Add Account")
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
            if viewModel.state == .accounts && !UserDefaults.standard.bool(forKey: hasShownAnimationKey) {
                DotLottieAnimation(fileName: "confettiAnimation", config: AnimationConfig(autoplay: true, loop: false)).view()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                            UserDefaults.standard.set(true, forKey: hasShownAnimationKey)
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
            if viewModel.state == .accounts {
                isCreatingAccount = false
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
                    .foregroundColor(Color.Neutral.tint2)
                    .font(.satoshi(size: 14, weight: .regular))
                Text(viewModel.totalBalance.displayValueWithTwoNumbersAfterDecimalPoint() + " ")
                    .foregroundColor(Color.MineralBlue.tint1)
                    .font(.satoshi(size: 28, weight: .medium))
                    .overlay(alignment: .bottomTrailing) {
                        Text("CCD")
                            .foregroundColor(Color.MineralBlue.tint1)
                            .font(.satoshi(size: 12, weight: .regular))
                            .offset(x: 26, y: -4)
                    }
                
                Text("\(viewModel.atDisposal.displayValueWithTwoNumbersAfterDecimalPoint()) at disposal")
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
                    AnyView(OnRampAnchorView())
                ]
            })
            .frame(maxWidth: .infinity)
            .frame(height: 132)
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
                        isCreatingAccount: $isCreatingAccount,
                        state: .accounts,
                        viewModel: vm,
                        onQrTap: { accountQr = (vm.account as? AccountEntity) },
                        onSendTap: { router?.showSendFundsFlow(vm.account) },
                        onShowPlusTap: { onRampFlowShown.toggle() }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        router?.showAccountDetail(vm.account)
                        Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Show account detail")
                    }
                }
            }
            .transition(.opacity)
            
        case .createAccount:
            VStack {
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount,
                                       onCreateAccount: {
                    self.isCreatingAccount = true
                    self.router?.createAccountFromOnboarding(isCreatingAccount: $isCreatingAccount)
                    Task { await viewModel.reload() }
                },
                                       state: .createAccount)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .transition(.opacity)
            
        case .createIdentity:
            VStack {
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .createIdentity)
                        .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: {
                    self.router?.showCreateIdentityFlow()
                    Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Create Identity")
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
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .identityVerification)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .transition(.opacity)

        case .verificationFailed:
            VStack {
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, onIdentityVerification: { self.router?.showCreateIdentityFlow() }, state: .verificationFailed)
                        .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .transition(.opacity)

        case .saveSeedPhrase:
            VStack {
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .saveSeedPhrase)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    isShowPasscodeViewShown = true
                    Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Save Seed Phrase")
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
            HStack(alignment: .top, spacing: 16) {
                Image("onramp_flow_icon")
                VStack(alignment: .leading, spacing: 5) {
                    Text("Where is CCD available?")
                        .font(.satoshi(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.08))
                        .frame(alignment: .leading)
                    Text("CCD is listed in the following exchanges and services. ")
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.3, green: 0.31, blue: 0.28))
                        .frame(alignment: .leading)
                    Button(action: {
                        if !SettingsHelper.isIdentityConfigured() {
                            self.router?.showNotConfiguredAccountPopup()
                        } else {
                            onRampFlowShown.toggle()
                            Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "OnRamp Banner")
                        }
                    }, label: {
                        HStack {
                            Text("See more")
                                .font(Font.satoshi(size: 14, weight: .bold))
                                .lineSpacing(24)
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                    })
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
