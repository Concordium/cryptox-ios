//
//  HomeScreenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import DotLottie

struct ActionItem: Identifiable {
    let id = UUID()
    let iconName: String
    let label: String
    let action: () -> Void
}

struct HomeScreenView: View {
    @ObservedObject var viewModel: AccountsMainViewModel
    @State private var activeAccountViewModel: AccountDetailViewModel?
    @EnvironmentObject var navigationManager: NavigationManager
    @State var showTooltip: Bool = false
    @State private var showManageTokenList: Bool = false
    @EnvironmentObject var updateTimer: UpdateTimer
    @State private var isNewTokenAdded: Bool = false
    @State private var previousState: AccountsMainViewState?
    @State var onRampFlowShown = false
    @State private var selectedPage = 0
    @State private var isCreatingAccount = false
    @State private var hasShownAnimationKey = "showConfettiAnimation"
    @State private var geometrySize: CGSize?
    @State var isShowPasscodeViewShown = false
    @State var phrase: [String]?
    @State var isLoading = false
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    @AppStorage("isShouldShowOnrampMessage") private var isShouldShowOnrampMessage = true
    
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
            GeometryReader { geometry in
                VStack {
                    if isLoading {
                        ScrollView {
                            HomeScreenViewSkeleton()
                        }
                    } else {
                        if viewModel.state == .accounts {
                            ScrollView {
                                homeViewContent()
                            }
                        } else {
                            homeViewContent()
                        }
                    }
                }
                .onReceive(updateTimer.tick) { _ in
                    Task {
                        await self.viewModel.reload()
                    }
                }
                .padding(.bottom, 20)
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
                .onChange(of: geometry.size) { _ in
                        geometrySize = geometry.size
                }
                .onChange(of: viewModel.selectedAccount?.address) { _ in
                    changeAccountDetailViewModel()
                }
                .refreshable { Task { await viewModel.reload() } }
                .onAppear {
                    updateTimer.start()
                    returnToHome()
                    Task {
                        isLoading = true
                        await viewModel.reload()
                        isLoading = false
                    }
                    Tracker.track(view: ["Home screen"])
                }
                .onDisappear { updateTimer.stop() }            }
            .modifier(AppBackgroundModifier())
            .modifier(NavigationDestinationBuilder(router: router, onAddressPicked: onAddressPicked))
        }
    }
    
    
    // MARK: - Views
    
    func homeViewContent() -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
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
                topBarControls()
                balanceSection()
            }
            .padding(.horizontal, 18)
            accountActionButtonsSection()
                .padding(.horizontal, 5)
                .padding(.top, 40)
            
            if viewModel.isBackupAlertShown {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("backup.recommendation.message".localized)
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .padding(.top, 40)
            }
            if isShouldShowOnrampMessage {
                NewsPageView(selectedTab: $selectedPage, views: {
                    [
                        AnyView(onrampView())
                    ]
                })
            }
            
            accountStatesView
                .padding(.horizontal, viewModel.state != .accounts ? 18 : 0)
                .padding(.top, isShouldShowOnrampMessage ? 0 : 40)
        }
    }
    
    func topBarControls() -> some View {
        HStack() {
            if !viewModel.accounts.isEmpty {
                HStack(spacing: 5) {
                    Image("dot\(getDotImageIndex())")
                    Text("\(viewModel.selectedAccount?.displayName ?? "")")
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
            Spacer()
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
    }
    
    func balanceSection() -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                Text("\(balanceDisplayValue(viewModel.selectedAccount?.forecastBalance)) CCD")
                    .font(.plexSans(size: 55, weight: .bold))
                    .dynamicTypeSize(.xSmall ... .xxLarge)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(alignment: .leading)
                    .modifier(RadialGradientForegroundStyleModifier())
                    .padding(.trailing, 30)
                
                Button {
                    showTooltip.toggle()
                } label: {
                    Image("info_gradient")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .popover(isPresented: $showTooltip, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing, content: {
                    infoTooltip
                        .frame(width: 200)
                        .presentationBackground(.white)
                        .presentationCompactAdaptation(.popover)
                })
                .offset(x: -5, y: 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let account = viewModel.selectedAccount, account.isStaking {
                Text("\(balanceDisplayValue(viewModel.selectedAccount?.forecastAtDisposalBalance)) CCD " + "accounts.atdisposal".localized)
                    .font(.satoshi(size: 15, weight: .medium))
                    .modifier(RadialGradientForegroundStyleModifier())
            }
            if let stakedAmount = viewModel.selectedAccount?.stakedAmount, stakedAmount != .zero {
                Text("\(stakedAmount.displayValueWithTwoNumbersAfterDecimalPoint()) CCD \("accounts.overview.staked".localized)")
                    .foregroundColor(Color.Neutral.tint1)
                    .font(.satoshi(size: 15, weight: .medium))
                    .padding(.top, 5)
                
            }
        }
    }
    
    func accountActionButtonsSection() -> some View {
        HStack {
            ForEach(actionItems) { item in
                VStack {
                    Image(item.iconName)
                        .frame(width: 24, height: 24)
                        .padding(11)
                        .background(.grey3)
                        .foregroundColor(.MineralBlue.blueish3)
                        .cornerRadius(50)
                    Text(item.label)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundColor(.MineralBlue.blueish2)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    if SettingsHelper.isIdentityConfigured() {
                        item.action()
                    }
                    else {
                        self.router?.showNotConfiguredAccountPopup()
                    }
                }
            }
        }
    }
    
    func onrampView() -> some View {
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
        .padding(.horizontal, 17)
        .padding(.vertical, 14)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var infoTooltip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total CCD balance")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Text("This balance shows your total CCD in this account. It does not include any other tokens.")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(nil)
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
                if let account = viewModel.selectedAccount as? AccountEntity {
                    navigationManager.navigate(to: .send(account))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Send funds")
                }
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                if let account = viewModel.selectedAccount as? AccountEntity {
                    navigationManager.navigate(to: .receive(account))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Account QR")
                }
            }),
            ActionItem(iconName: "Percent", label: "Earn", action: {
                guard let selectedAccount = viewModel.selectedAccount else { return }
                router?.showEarnFlow(selectedAccount)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Earn")
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                if let account = viewModel.selectedAccount as? AccountEntity {
                    navigationManager.navigate(to: .activity(account))
                    Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Activity")
                }
            })
        ]
        return actionItems
    }
    
    private func getDotImageIndex() -> Int {
        guard let selectedAccount = viewModel.selectedAccount else { return 1 }
        let matchingAcc = viewModel.accountViewModels.first { $0.account.address == selectedAccount.address }
        return matchingAcc?.dotImageIndex ?? 1
    }
    
    func balanceDisplayValue(_ balance: Int?) -> String {
        let gtuValue = GTU(intValue: balance)
        return gtuValue?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
    }
    
    func changeAccountDetailViewModel() {
        if let selectedAccount = viewModel.selectedAccount {
            if activeAccountViewModel?.account?.address != selectedAccount.address {
                activeAccountViewModel = AccountDetailViewModel(account: selectedAccount)
            }
        }
    }
}

extension HomeScreenView {
    // MARK: - Onboarding states
    @ViewBuilder
    private var accountStatesView: some View {
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
                .transition(.opacity)
            }
            
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
                    Text("create_wallet_step_3_title".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.blackMain)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(28)
                })
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
                    Text("create_wallet_step_2_title".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.blackMain)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(28)
                }
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
    
    private func returnToHome() {
        NotificationCenter.default.addObserver(forName: .returnToHomeTabBar, object: nil, queue: .main) { notification in
            if let needToReturn = notification.userInfo?["returnToHomeTabBar"] as? Bool, needToReturn {
                self.navigationManager.reset()
            }
        }
    }
}

struct HomeScreenViewSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Placeholder for top bar
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 32)
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                
                // Placeholder for balance section
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 40)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                
                // Placeholder for action buttons
                HStack {
                    ForEach(0..<5) { _ in
                        VStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 48, height: 48)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 12)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 18)
                
                // Placeholder for account states
                Spacer()
                    .padding(.bottom, 40)
                ForEach(0..<4) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 50)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                }
            }
            .redacted(reason: .placeholder)
            .padding(.bottom, 20)
        }
        .modifier(AppBackgroundModifier())
        .onAppear {
            withAnimation(Animation.linear(duration: 0.3).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
