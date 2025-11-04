//
//  HomeScreenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import Lottie

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
    @State private var shouldShowDismissBackupPopup = false
    @State var phrase: [String]?
    @State private var selectedActionId: Int?
    @State private var hasAppearedForTheFirstTime: Bool = false
    @State private var confettiPlayToken = 0
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowOnrampMessage") private var isShouldShowOnrampMessage = true
    @AppStorage("isShouldShowEarnBanner") private var isShouldShowEarnBanner = true
    @AppStorage("isShouldShowSeedphraseBackupBanner") private var isShouldShowSeedphraseBackupBanner = true
    @AppStorage("isShouldShowAllowNotificationsView") private var isShouldShowAllowNotificationsView = true

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
                        ZStack {
                            HomeViewContent
                            if shouldShowDismissBackupPopup {
                                Color.black.opacity(0.8)
                                    .ignoresSafeArea()
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: shouldShowDismissBackupPopup)
                                
                                DismissBackupPopup(
                                    isPresentingAlert: $shouldShowDismissBackupPopup,
                                    onBackupTapped: {
                                        shouldShowDismissBackupPopup = false
                                        isShowPasscodeViewShown = true
                                    },
                                    onHideTapped: {
                                        isShouldShowSeedphraseBackupBanner = false
                                    }
                                )
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                                .zIndex(2)
                                .animation(.easeInOut(duration: 0.3), value: shouldShowDismissBackupPopup)
                            }
                        }
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
            .overlay {
                if viewModel.state == .accounts, !UserDefaults.standard.bool(forKey: hasShownAnimationKey) {

                    LottiePlayer(
                        name: "confettiAnimation",
                        loopMode: .playOnce,
                        playToken: confettiPlayToken,
                        scale: 1.3
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                            UserDefaults.standard.set(true, forKey: hasShownAnimationKey)
                        }
                    }
                }
            }
            .overlay(alignment: .center) {
                if !UIApplication.shared.isRegisteredForRemoteNotifications && isShouldShowAllowNotificationsView {
                    AllowNotificationsPopup(isVisible: $isShouldShowAllowNotificationsView)
                }
            }
            .onChange(of: viewModel.selectedAccount) { _ in
                changeAccountDetailViewModel()
            }
            .onAppear {
                returnToHome()
                Task {
                    await viewModel.reload()
                }
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

                let suspendedAccounts = viewModel.suspendedOrPrimedAccounts()

                if suspendedAccounts.count > 1 {
                    Button {
                        navigationManager.navigate(to: .accountsOverview(viewModel))
                    } label: {
                        StakerSuspensionStateView(message: "multiple.accounts.suspended".localized, type: nil, stakeType: nil)
                    }
                } else if let account = suspendedAccounts.first {
                    let isSuspended = account.baker?.isSuspended == true || account.delegation?.isSuspended == true
                    let isPrimed = account.baker?.isPrimedForSuspension == true || account.delegation?.isPrimedForSuspension == true

                    let suspensionType: StakerSuspensionStateView.StakerSuspensionState? =
                        isSuspended ? .suspended : (isPrimed ? .primedForSuspension : nil)

                    let stakeType: StakerSuspensionStateView.StakerType? =
                        account.baker?.isSuspended == true || account.baker?.isPrimedForSuspension == true ? .baker : .delegation

                    if let type = suspensionType, let stake = stakeType {
                        Button {
                            if account.address != viewModel.selectedAccount?.account?.address {
                                viewModel.changeCurrentAccount(account)
                            }
                            navigationManager.navigate(to: .earn(account))
                        } label: {
                            StakerSuspensionStateView(message: nil, type: type, stakeType: stake)
                        }
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
                
                // Seedphrase backup reminder banner
                if viewModel.accounts.count >= 1 {
                    if !isUserMakeBackup && isShouldShowSeedphraseBackupBanner && identitiesService.mobileWallet.hasSetupRecoveryPhrase {
                        SeedphraseBackupBannerView(
                            onBackupNow: {
                                // Show passcode view to get password hash, then navigate to seedphrase backup screen
                                isShowPasscodeViewShown = true
                            },
                            onHideAnyway: {
                                withAnimation(.easeInOut) {
                                    shouldShowDismissBackupPopup = true
                                }
                            }
                        )
                    } else if  viewModel.selectedAccount?.account?.forecastBalance == 0,
                               isShouldShowOnrampMessage && (!isShouldShowSeedphraseBackupBanner || isUserMakeBackup) {
                        OnrampView
                    } else if viewModel.selectedAccount?.account?.delegation == nil && isShouldShowEarnBanner {
                        EarnView
                    }
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
        }
        .onTapGesture {
            if !SettingsHelper.isIdentityConfigured() {
                self.router?.showNotConfiguredAccountPopup()
            } else if let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity {
                navigationManager.navigate(to: .earn(selectedAccount))
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
            }),
            ActionItem(iconName: "send", label: "Send", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .send(account, tokenType: .ccd, to: nil))
                }
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .receive(account))
                }
            }),
            ActionItem(iconName: "Percent", label: "Earn", action: {
                guard let selectedAccount = viewModel.selectedAccount?.account as? AccountEntity else { return }
                navigationManager.navigate(to: .earn(selectedAccount))
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                if let account = viewModel.selectedAccount?.account as? AccountEntity {
                    navigationManager.navigate(to: .activity(account))
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
                        mode: .view
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
                                                  storageManager: ServicesProvider.defaultProvider().storageManager()),
                     identitiesService: nil) { pwHash in
            isShowPasscodeViewShown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.router?.showSaveSeedPhraseFlow(pwHash: pwHash, identitiesService: identitiesService) { phrase in
                    if identitiesService.mobileWallet.hasSetupRecoveryPhrase {
                        self.phrase = phrase
                        // Mark backup as completed and hide banner
                        isUserMakeBackup = true
                        isShouldShowSeedphraseBackupBanner = false
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
    
    let message: String?
    let type: StakerSuspensionState?
    let stakeType: StakerType?
    
    var body: some View {
        HStack(spacing: 16) {
            Image("Pause")
            
            if let message = message {
                Text(message)
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundStyle(Color.white)
            } else if let type = type, let stakeType = stakeType {
                Text(type.title(for: stakeType))
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundStyle(Color.white)
            }
            
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

struct SeedphraseBackupBannerView: View {
    let onBackupNow: () -> Void
    let onHideAnyway: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .center) {
                    Image("restore-seed-phrase")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                }
                .padding(0)
                .frame(width: 40, height: 40, alignment: .center)
                .background(.white.opacity(0.1))
                .cornerRadius(9999)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup Your Wallet")
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Keep your account safe by making a copy of your wallet seed phrase")
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundColor(.semanticContentSecondary)
                        .multilineTextAlignment(.leading)
                }
                .onTapGesture {
                    onBackupNow()
                }
                
                Spacer()
                
                Button(action: onHideAnyway) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.semanticContentPrimary.opacity(0.6))
                        .font(.system(size: 20))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(.semanticBorderTertiary, lineWidth: 1)
        )
    }
}
