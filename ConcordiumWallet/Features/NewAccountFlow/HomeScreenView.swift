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

enum AccountNavigationPaths: Hashable {
    case accountsOverview
    case manageTokens
    case tokenDetails(token: AccountDetailAccount)
    case buy
    case send
    case earn
    case activity
    case addToken
    case addTokenDetails(token: AccountDetailAccount)
    case transactionDetails(transaction: TransactionDetailViewModel)
}

struct HomeScreenView: View {
    @StateObject var viewModel: AccountsMainViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    @State var showTooltip: Bool = false
    @State var accountQr: AccountEntity?
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
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    @AppStorage("isShouldShowOnrampMessage") private var isShouldShowOnrampMessage = true
    
    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    weak var router: AccountsMainViewDelegate?
    var actionItems: [ActionItem]  {
        return accountActionItems()
    }
    var dependencyProvider = ServicesProvider.defaultProvider()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            GeometryReader { geometry in
                VStack {
                    if viewModel.isLoading {
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
                .navigationDestination(for: AccountNavigationPaths.self, destination: { destination in
                    navigateTo(destination)
                })
                .sheet(item: $accountQr) { account in
                    AccountQRView(account: account)
                }
                .fullScreenCover(isPresented: $isShowPasscodeViewShown, content: {
                    passcodeView
                })
                .onChange(of: showManageTokenList) { newValue in
                    if showManageTokenList {
                        navigationManager.navigate(to: .manageTokens)
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
                .refreshable { Task { await viewModel.reload() } }
                .onAppear { Task { await viewModel.reload() } }
                .onAppear { updateTimer.start() }
                .onDisappear { updateTimer.stop() }
                .onAppear { Tracker.track(view: ["Home screen"]) }
            }
            .modifier(AppBackgroundModifier())
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
        }
    }
    
    func topBarControls() -> some View {
        HStack() {
            if !viewModel.accounts.isEmpty {
                HStack(spacing: 5) {
                    Image("dot\(getDotImageIndex())")
                    Text("\(viewModel.selectedAccount?.displayName ?? "")")
                        .font(.satoshi(size: 15, weight: .medium))
                    Image(systemName: "chevron.up.chevron.down")
                        .tint(.greyAdditional)
                }
                .onTapGesture {
                    navigationManager.navigate(to: .accountsOverview)
                }
            }
            Spacer()
            Image("ico_scan")
                .resizable()
                .frame(width: 32, height: 32)
                .tint(.MineralBlue.blueish3)
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
                guard let selectedAccount = viewModel.selectedAccount else { return }
                router?.showSendFundsFlow(selectedAccount)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Send funds")
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                accountQr = (viewModel.selectedAccount as? AccountEntity)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Account QR")
            }),
            ActionItem(iconName: "Percent", label: "Earn", action: {
                guard let selectedAccount = viewModel.selectedAccount else { return }
                router?.showEarnFlow(selectedAccount)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Earn")
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                navigationManager.navigate(to: .activity)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "Activity")
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
            if let vm = viewModel.accountDetailViewModel {
                AccountTokenListView(viewModel: vm, showManageTokenList: $showManageTokenList, path: $navigationManager.path, mode: .normal)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
                    .padding(.top, isShouldShowOnrampMessage ? 0 : 40)
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
                    Text("create_wallet_step_2_title".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(.blackMain)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
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
    
    // MARK: - Navigation
    
    private func navigateTo(_ destination: AccountNavigationPaths) -> some View {
        Group {
            switch destination {
            case .accountsOverview:
                AccountsOverviewView(path: $navigationManager.path, viewModel: viewModel, router: router)
            case .buy:
                CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
                    .modifier(NavigationViewModifier(title: "Buy CCD") {
                        navigationManager.pop()
                    })
            case .manageTokens:
                if let vm = viewModel.accountDetailViewModel {
                    ManageTokensView(viewModel: vm, path: $navigationManager.path, isNewTokenAdded: $isNewTokenAdded)
                } else {
                    EmptyView()
                }
            case .tokenDetails(let token):
                if let vm = viewModel.accountDetailViewModel, let selectedAccount = viewModel.selectedAccount {
                    TokenBalanceView(token: token, path: $navigationManager.path, selectedAccount: selectedAccount, viewModel: vm, router: self.router)
                } else {
                    EmptyView()
                }
            case .send, .earn:
                EmptyView()
            case .addToken:
                if let selectedAccount = viewModel.selectedAccount {
                    AddTokenView(
                        path: $navigationManager.path,
                        viewModel: .init(storageManager: dependencyProvider.storageManager(),
                                         networkManager: dependencyProvider.networkManager(),
                                         account: selectedAccount),
                        searchTokenViewModel: SearchTokenViewModel(
                            cis2Service: CIS2Service(
                                networkManager: dependencyProvider.networkManager(),
                                storageManager: dependencyProvider.storageManager()
                            )
                        ),
                        onTokenAdded: { isNewTokenAdded = true }
                    )
                } else {
                    EmptyView()
                }
            case .addTokenDetails(let token):
                TokenDetailsView(token: token, isAddTokenDetails: true, showRawMd: .constant(false))
                    .modifier(NavigationViewModifier(title: "Add token", backAction: {
                        navigationManager.pop()
                    }))
            case .activity:
                if let selectedAccount = viewModel.selectedAccount {
                    TransactionsView(viewModel: TransactionsViewModel(account: selectedAccount, dependencyProvider: ServicesProvider.defaultProvider())) { vm in
                        navigationManager.navigate(to: .transactionDetails(transaction: vm))
                    }
                    .modifier(AppBackgroundModifier())
                    .modifier(NavigationViewModifier(title: "Activity") {
                        navigationManager.pop()
                    })
                }
            case .transactionDetails(let transaction):
                TransactionDetailView(viewModel: transaction)
                    .modifier(NavigationViewModifier(title: "Transaction Details", backAction: {
                        navigationManager.pop()
                    }))
            }
        }
    }
}

class NavigationManager: ObservableObject {
    @Published var path: [AccountNavigationPaths] = []
    
    func navigate(to destination: AccountNavigationPaths) {
        path.append(destination)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func reset() {
        path.removeAll()
    }
}

struct HomeScreenViewSkeleton: View {
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
    }
}
