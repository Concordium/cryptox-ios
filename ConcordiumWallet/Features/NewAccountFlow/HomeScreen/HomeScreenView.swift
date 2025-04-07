//
//  HomeScreenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
//import DotLottie

struct ActionItem: Identifiable {
    let id = UUID()
    let iconName: String
    let label: String
    let action: () -> Void
}

struct HomeScreenView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var updateTimer: UpdateTimer
    
    @ObservedObject var viewModel: AccountsMainViewModel
    
    @State private var activeAccountViewModel: AccountDetailViewModel?
    @State var showTooltip: Bool = false
    @State private var showManageTokenList: Bool = false
    @State private var isNewTokenAdded: Bool = false
    @State private var previousState: AccountsMainViewState?
    @State var onRampFlowShown = false
    @State private var selectedPage = 0
    @State private var isCreatingAccount = false
    @State private var hasShownAnimationKey = "showConfettiAnimation"
    @State var isShowPasscodeViewShown = false
    @State var phrase: [String]?
    @State private var selectedActionId: Int?
    @State private var hasAppearedForTheFirstTime: Bool = false
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowOnrampMessage") private var isShouldShowOnrampMessage = true
    @AppStorage("isShouldShowEarnBanner") private var isShouldShowEarnBanner = true

    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    weak var router: AccountsMainViewDelegate?
    var onAddressPicked = PassthroughSubject<String, Never>()
    var actionItems: [ActionItem]  {
        return accountActionItems()
    }
    var dependencyProvider = ServicesProvider.defaultProvider()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            GeometryReader { proxy in
                Group {
                    if viewModel.isLoadedAccounts {
                        HomeViewContent
                    } else {
                        HomeScreenViewSkeleton()
                    }
                }
                .frame(width: proxy.size.width)
            }
            .onReceive(updateTimer.tick) { _ in
                Task {
                    await self.viewModel.reload()
                }
            }
            .refreshable {
                Task {
                    await self.viewModel.reload()
                }
            }
            .onTapGesture {
                showTooltip = false
            }
            .fullScreenCover(isPresented: $isShowPasscodeViewShown, content: {
                passcodeView
            })
            .onChange(of: showManageTokenList) { newValue in
                if showManageTokenList {
                    navigationManager.navigate(to: .manageTokens(viewModel))
                }
            }
            .onChange(of: viewModel.state) { newState in
                if newState != .accounts {
                    previousState = newState
                }
                if viewModel.state == .accounts {
                    isCreatingAccount = false
                }
            }
//            .overlay(content: {
//                if viewModel.state == .accounts && !UserDefaults.standard.bool(forKey: hasShownAnimationKey) {
//                    DotLottieAnimation(fileName: "confettiAnimation", config: AnimationConfig(autoplay: true, loop: false)).view()
//                        .allowsHitTesting(false)
//                        .opacity(!UserDefaults.standard.bool(forKey: hasShownAnimationKey) ? 1 : 0)
//                        .onAppear {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
//                                UserDefaults.standard.set(true, forKey: hasShownAnimationKey)
//                            }
//                        }
//                }
//            })
            .onChange(of: viewModel.selectedAccount) { _ in
                changeAccountDetailViewModel()
            }
            .onAppear {
                returnToHome()
                Task {
                    await viewModel.reload()
                }
                Tracker.track(view: ["Home screen"])
                updateTimer.start()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { updateTimer.stop() }
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.accounts.isEmpty {
                        HStack(spacing: 5) {
                            Image(getDotImageIndex() == 1 ? "Dot1" : "dot\(getDotImageIndex())")
                            Text("\(viewModel.selectedAccount?.account?.displayName ?? "")")
                                .font(.satoshi(size: 15, weight: .medium))
                            Image("CaretUpDown")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .tint(.greyAdditional)
                        }
                        .onTapGesture {
                            navigationManager.navigate(to: .accountsOverview(viewModel))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image("ico_scan")
                        .onTapGesture {
                            if SettingsHelper.isIdentityConfigured() {
                                self.router?.showScanQRFlow()
                                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Scan QR")
                            } else {
                                self.router?.showNotConfiguredAccountPopup()
                            }
                        }
                }
            })
            .modifier(AppBackgroundModifier())
            .modifier(NavigationDestinationBuilder(router: router, onAddressPicked: onAddressPicked))
        }
    }
    
    
    // MARK: - Views
    
    private var HomeViewContent: some View {
        ScrollView {
            VStack(spacing: 40) {
                if viewModel.isBackupAlertShown {
                    HStack {
                        Text("File wallet is selected")
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.leading, 16)
                        Spacer()
                        Image("arrowsClockwise")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .background(Color(red: 0, green: 0.3, blue: 0.37))
                    .cornerRadius(18)
                    .onTapGesture {
                        self.router?.showExportFlow()
                    }
                }
                
                if viewModel.selectedAccount?.account?.baker?.isSuspended == true || viewModel.selectedAccount?.account?.delegation?.isSuspended == true {
                    Button {
                        if let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity {
                            navigationManager.navigate(to: .earn(selectedAccount))
                        }
                    } label: {
                        StakerSuspensionStateView(type: .suspended, stakeType: viewModel.selectedAccount?.account?.baker?.isSuspended == true ? .baker : .delegation)
                    }
                } else if viewModel.selectedAccount?.account?.baker?.isPrimedForSuspension == true || viewModel.selectedAccount?.account?.delegation?.isPrimedForSuspension == true {
                    Button {
                        if let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity {
                            navigationManager.navigate(to: .earn(selectedAccount))
                        }
                    } label: {
                        StakerSuspensionStateView(type: .primedForSuspension, stakeType: viewModel.selectedAccount?.account?.baker?.isPrimedForSuspension == true ? .baker : .delegation)
                    }
                }
                
                balanceSection()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                accountActionButtonsSection()
                
                if viewModel.isBackupAlertShown {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text("backup.recommendation.message".localized)
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                if  viewModel.selectedAccount?.account?.forecastBalance == 0,
                    viewModel.selectedAccount?.account?.delegation != nil,
                    isShouldShowOnrampMessage {
                        OnrampView
                } else if viewModel.selectedAccount?.account?.delegation == nil && isShouldShowEarnBanner {
                    EarnView
                }
                
                AccountStatesView
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .refreshable { Task { await viewModel.reload() } }
        .padding(.bottom, 20)
        .safeAreaInset(edge: .bottom) {
            switch viewModel.state {
            case .createIdentity:
                Button(action: {
                    self.router?.showCreateIdentityFlow()
                    Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Create Identity")
                }, label: {
                    Text("create_wallet_step_3_title".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.blackMain)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(28)
                })
                .padding()
            case .saveSeedPhrase:
                Button {
                    isShowPasscodeViewShown = true
                    Tracker.trackContentInteraction(name: "Onboarding", interaction: .clicked, piece: "Save Seed Phrase")
                } label: {
                    Text("create_wallet_step_2_title".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.blackMain)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(28)
                }
                .padding()
            default: EmptyView()
            }
        }
    }
    
    func balanceSection() -> some View {
        VStack(alignment: .leading) {
            Text("\(balanceDisplayValue(viewModel.selectedAccount?.account?.forecastBalance)) CCD")
                .contentTransition(.numericText())
                .frame(alignment: .leading)
                .font(.plexSans(size: 55, weight: .semibold))
                .dynamicTypeSize(.xSmall ... .xxLarge)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(alignment: .leading)
                .modifier(RadialGradientForegroundStyleModifier())
                .overlay(alignment: .topTrailing) {
                    Button {
                        showTooltip.toggle()
                    } label: {
                        Image("info_gradient")
                    }
                    .popover(isPresented: $showTooltip, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing, content: {
                        InfoTooltipView
                            .frame(width: 200)
                            .presentationBackground(Color(red: 0.97, green: 0.96, blue: 0.96))
                            .presentationCompactAdaptation(.popover)
                    })
                    .offset(x: 20, y: 8)
                }
                .padding(.trailing, 20)
            
            if let account = viewModel.selectedAccount?.account, account.isStaking {
                Text("\(balanceDisplayValue(account.forecastAtDisposalBalance)) CCD " + "accounts.atdisposal".localized)
                    .font(.satoshi(size: 15, weight: .medium))
                    .modifier(RadialGradientForegroundStyleModifier())
            }
        }
    }
    
    func accountActionButtonsSection() -> some View {
        HStack {
            ForEach(Array(actionItems.enumerated()), id: \.offset) { (index, item) in
                Button(
                    action: {
                        selectedActionId = index
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            selectedActionId = nil
                            if SettingsHelper.isIdentityConfigured() {
                                item.action()
                            }
                            else {
                                self.router?.showNotConfiguredAccountPopup()
                            }
                        }
                    }, label: {
                        VStack {
                            Image(item.iconName)
                                .frame(width: 24, height: 24)
                                .padding(11)
                                .background(selectedActionId == index ? .grey4 : .grey3)
                                .foregroundColor(.MineralBlue.blueish3)
                                .cornerRadius(50)
                            Text(item.label)
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundColor(.MineralBlue.blueish2)
                                .padding(.top, 2)
                        }
                        .contentShape(.rect)
                    })
                .buttonStyle(.plain)
                .overlay(alignment: .topTrailing) {
                    if item.label == "Earn" {
                        if (viewModel.selectedAccount?.account?.baker?.isSuspended == true || viewModel.selectedAccount?.account?.delegation?.isSuspended == true) || (viewModel.selectedAccount?.account?.baker?.isPrimedForSuspension == true || viewModel.selectedAccount?.account?.delegation?.isPrimedForSuspension == true) {
                            Circle().fill(.attentionRed)
                                .frame(width: 8, height: 8)
                                .offset(x: 0, y: 4)
                        }
                    }
                }
                
                if index < actionItems.endIndex-1 {
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private var OnrampView: some View {
        HStack(alignment: .top, spacing: 17) {
            Image("onramp_ccd")
            VStack(alignment: .leading, spacing: 2) {
                Text("Get your CCD")
                    .font(.satoshi(size: 15, weight: .medium))
                
                Text("And be part of a safer digital future")
                    .font(.satoshi(size: 12, weight: .regular))
            }
            Spacer()
            Image(systemName: "xmark.circle")
                .tint(.MineralBlue.blueish3)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isShouldShowOnrampMessage = false
                    }
                }
        }
        .onTapGesture {
            if !SettingsHelper.isIdentityConfigured() {
                self.router?.showNotConfiguredAccountPopup()
            } else {
                navigationManager.navigate(to: .buy)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "OnRamp Banner")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }
    
    private var EarnView: some View {
        HStack(alignment: .center, spacing: 19) {
            Image("Percent")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.greenMain)
                .frame(width: 35, height: 35)
            VStack(alignment: .leading, spacing: 2) {
                Text("earn.info.title.part1".localized + " ")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.white) +
                Text("6%")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.greenMain)
                Text("staking.carousel.desc".localized)
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "xmark.circle")
                .tint(.MineralBlue.blueish3)
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isShouldShowEarnBanner = false
                    }
                }
                .frame(alignment: .top)
                .padding(.bottom, 15)
        }
        .onTapGesture {
            if !SettingsHelper.isIdentityConfigured() {
                self.router?.showNotConfiguredAccountPopup()
            } else if let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity {
                navigationManager.navigate(to: .earn(selectedAccount))
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Earn Banner")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private var InfoTooltipView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total CCD balance")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Text("This balance shows your total CCD in this account. It does not include any other tokens.")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.96))
        )
    }
    
    // MARK: - Helpers
    
    private func accountActionItems() -> [ActionItem] {
        let actionItems = [
            ActionItem(iconName: "buy", label: "Buy", action: {
                navigationManager.navigate(to: .buy)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Buy")
            }),
            ActionItem(iconName: "send", label: "Send", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .send(account, tokenType: .ccd))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Send funds")
                }
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .receive(account))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Account QR")
                }
            }),
            ActionItem(iconName: "Percent", label: "Earn", action: {
                guard let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity else { return }
                navigationManager.navigate(to: .earn(selectedAccount))

                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Earn")
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .activity(account))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Activity")
                }
            })
        ]
        return actionItems
    }
    
    private func getDotImageIndex() -> Int {
        guard let selectedAccount = viewModel.selectedAccount else { return 1 }
        let matchingAcc = viewModel.accountViewModels.first { $0.account?.address == selectedAccount.address }
        return matchingAcc?.dotImageIndex ?? 1
    }
    
    func balanceDisplayValue(_ balance: Int?) -> String {
        let gtuValue = GTU(intValue: balance)
        return gtuValue?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
    }
    
    func changeAccountDetailViewModel() {
        if let selectedAccount = viewModel.selectedAccount?.account {
            activeAccountViewModel = AccountDetailViewModel(account: selectedAccount)
            AppSettings.lastSelectedAccountAddress = selectedAccount.address
        }
    }
}

extension HomeScreenView {
    // MARK: - Onboarding states
    @ViewBuilder
    private var AccountStatesView: some View {
        Group {
            switch viewModel.state {
            case .empty:
                VStack {
                    Spacer()
                    EmptyView()
                    Spacer()
                }
            case .accounts:
                if let vm = activeAccountViewModel {
                    AccountTokenListView(
                        viewModel: vm,
                        showManageTokenList: $showManageTokenList,
                        path: $navigationManager.path,
                        mode: .normal
                    )
                    .frame(maxWidth: .infinity)
                }
            case .createAccount:
                AccountPreviewCardView(
                    isCreatingAccount: $isCreatingAccount,
                    onCreateAccount: {
                        self.isCreatingAccount = true
                        self.router?.createAccountFromOnboarding(isCreatingAccount: $isCreatingAccount)
                        Task { await viewModel.reload() }
                    },
                    state: .createAccount
                )
            case .createIdentity:
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .createIdentity)
                
            case .identityVerification:
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .identityVerification)
                
            case .verificationFailed:
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, onIdentityVerification: { self.router?.showCreateIdentityFlow() }, state: .verificationFailed)
            case .saveSeedPhrase:
                AccountPreviewCardView(isCreatingAccount: $isCreatingAccount, state: .saveSeedPhrase)
            }
        }
        .transition(.opacity)
        .animation(.smooth, value: viewModel.state)
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
    
    private func returnToHome() {
        NotificationCenter.default.addObserver(forName: .returnToHomeTabBar, object: nil, queue: .main) { notification in
            if let needToReturn = notification.userInfo?["returnToHomeTabBar"] as? Bool, needToReturn {
                self.navigationManager.reset()
            }
        }
    }
}


struct StakerSuspensionStateView: View {
    enum StakerSuspensionState {
        case suspended, primedForSuspension
        
        
        func title(for type: StakerType) -> String {
            switch (self, type) {
            case (.suspended, .baker):
                return "Your validation has been suspended"
            case (.primedForSuspension, .baker):
                return "Your validation is primed for suspension"
            case (.suspended, .delegation):
                return "Your validator has been suspended"
            case (.primedForSuspension, .delegation):
                return "Your validator is primed for suspension"
            }
        }
    }
    
    enum StakerType {
        case baker
        case delegation
    }
    
    let type: StakerSuspensionState
    let stakeType: StakerType
    var body: some View {
        HStack(spacing: 16) {
            Image("Pause")
            Text(type.title(for: stakeType))
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundStyle(Color.white)
            Spacer(minLength: 0)
            Image("ArrowUp")
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.attentionRed)
        .background(
            EllipticalGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.62, green: 0.95, blue: 0.92), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.93, green: 0.85, blue: 0.75), location: 0.50),
                    Gradient.Stop(color: Color(red: 0.64, green: 0.6, blue: 0.89), location: 1.00),
                ],
                center: UnitPoint(x: 0.31, y: 0.49)
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.25), radius: 7.65, x: 0, y: -6)
    }
}
