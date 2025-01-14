//
//  HomeScreenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct ActionItem: Identifiable {
    let id = UUID()
    let iconName: String
    let label: String
    let action: () -> Void
}

enum AccountNavigationPaths: Hashable {
    case accountsOverview
    case manageTokens
    case tokenDetails
    case buy
    case send
//    case receive
    case earn
    case activity
    case addToken
    case addTokenDetails(token: AccountDetailAccount)
}

struct HomeScreenView: View {
    @StateObject var viewModel: AccountsMainViewModel
    @State var showTooltip: Bool = false
    @State var accountQr: AccountEntity?
    @State private var showTokenDetails: Bool = false
    @State private var showManageTokenList: Bool = false
    @State private var selectedToken: AccountDetailAccount?
    //    @EnvironmentObject var updateTimer: UpdateTimer
    @State private var path: [AccountNavigationPaths] = []
    @State private var isNewTokenAdded: Bool = false
    
    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true
    @AppStorage("isShouldShowOnrampMessage") private var isShouldShowOnrampMessage = true

    var accountDetailViewModel: AccountDetailViewModel2? {
        guard let selectedAccount = viewModel.selectedAccount else { return nil }
        return AccountDetailViewModel2(account: selectedAccount)
    }

    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    weak var router: AccountsMainViewDelegate?
    @State var onRampFlowShown = false
    @State private var selectedPage = 0
    var actionItems: [ActionItem]  {
        return accountActionItems()
    }
    var dependencyProvider = ServicesProvider.defaultProvider()
    
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        topBarControls()
                        balanceSection()
                    }
                    .padding(.horizontal, 18)
                    accountActionButtonsSection()
                        .padding(.top, 40)
                    if isShouldShowOnrampMessage {
                        NewsPageView(selectedTab: $selectedPage, views: {
                            [
                                AnyView(onrampView())
                            ]
                        })
                    }
                    
                    if let vm = accountDetailViewModel {
                        AccountTokenListView(viewModel: vm, showTokenDetails: $showTokenDetails, showManageTokenList: $showManageTokenList, selectedToken: $selectedToken, mode: .normal)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height / 2)
                            .padding(.top, 40)
                    }
                }
                .onTapGesture {
                    showTooltip = false
                }
                .navigationDestination(for: AccountNavigationPaths.self, destination: { destination in
                    switch destination {
                    case .accountsOverview:
                        AccountsOverviewView(viewModel: viewModel)
                        //                    case .receive:
                        //                        if let accountQr {
                        //                            AccountQRView(account: accountQr)
                        //                        }
                    case .buy:
                        CCDOnrampView(dependencyProvider: viewModel.dependencyProvider)
                    case .manageTokens:
                        if let vm = accountDetailViewModel {
                            ManageTokensView(viewModel: vm, path: $path, isNewTokenAdded: $isNewTokenAdded)
                        }
                    case .tokenDetails:
                        if let vm = accountDetailViewModel, let selectedToken {
                            TokenBalanceView(token: selectedToken, viewModel: vm, router: self.router)
                        }
                    case .send:
                        EmptyView()
                    case .earn:
                        EmptyView()
                    case .activity:
                        EmptyView()
                    case .addToken:
                        if let selectedAccount = viewModel.selectedAccount {
                            AddTokenView(path: $path,
                                         viewModel: .init(storageManager: self.dependencyProvider.storageManager(),
                                                          networkManager: self.dependencyProvider.networkManager(),
                                                          account: selectedAccount),
                                         searchTokenViewModel: SearchTokenViewModel(cis2Service:
                                                                                        CIS2Service(networkManager: self.dependencyProvider.networkManager(),
                                                                                                    storageManager: self.dependencyProvider.storageManager())), onTokenAdded: {
                                isNewTokenAdded = true
                            })
                        }
                    case .addTokenDetails(let token):
                        TokenDetailsView(token: token, isAddTokenDetails: true)
                            .navigationBarBackButtonHidden(true)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button {
                                        path.removeLast()
                                    } label: {
                                        Image("ico_back")
                                            .resizable()
                                            .foregroundColor(.greySecondary)
                                            .frame(width: 32, height: 32)
                                            .contentShape(.circle)
                                    }
                                }
                                ToolbarItem(placement: .principal) {
                                    VStack {
                                        Text("Add token")
                                            .font(.satoshi(size: 17, weight: .medium))
                                            .foregroundStyle(Color.white)
                                    }
                                }
                            }
                    }
                })
                .sheet(item: $accountQr) { account in
                    AccountQRView(account: account)
                }
                .onChange(of: selectedToken) { newValue in
                    if showTokenDetails {
                        path.append(.tokenDetails)
                    }
                }
                .onChange(of: showManageTokenList) { newValue in
                    if showManageTokenList {
                        path.append(.manageTokens)
                    }
                }
            }
            .modifier(AppBackgroundModifier())
        }
        .refreshable {
            await viewModel.reload()
        }
        .onAppear {
            Task {
                await viewModel.reload()
            }
        }
    }
    
    func topBarControls() -> some View {
        HStack() {
            HStack(spacing: 5) {
                Image(viewModel.dotImageName)
                Text("\(viewModel.selectedAccount?.displayName ?? "")")
                    .font(.satoshi(size: 15, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .tint(.greyAdditional)
            }
            .onTapGesture {
                path.append(.accountsOverview)
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
            HStack(alignment: .top, spacing: 4) {
                Text("\(balanceDisplayValue(viewModel.selectedAccount?.forecastBalance)) CCD")
                    .font(.plexSans(size: 55, weight: .medium))
                    .dynamicTypeSize(.xSmall ... .xxLarge)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .modifier(RadialGradientForegroundStyleModifier())
                
                Button {
                    showTooltip.toggle()
                } label: {
                    Image("info_gradient")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .offset(y: 8)
                }
                .popover(isPresented: $showTooltip, attachmentAnchor: .point(.bottomLeading), arrowEdge: .bottom, content: {
                    infoTooltip
                        .frame(width: 200)
                        .presentationBackground(.white)
                        .presentationCompactAdaptation(.popover)
                })
            }
            
            Text("\(balanceDisplayValue(viewModel.selectedAccount?.forecastAtDisposalBalance)) CCD " + "accounts.atdisposal".localized)
                .font(.satoshi(size: 15, weight: .medium))
                .modifier(RadialGradientForegroundStyleModifier())
        }
    }
    
    func accountActionButtonsSection() -> some View {
        HStack(alignment: .center) {
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
                    item.action()
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
                path.append(.buy)
                Tracker.trackContentInteraction(name: "Accounts", interaction: .clicked, piece: "OnRamp Banner")
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 14)
        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }
    
    func balanceDisplayValue(_ balance: Int?) -> String {
        let gtuValue = GTU(intValue: balance)
        return gtuValue?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
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
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.96))
        )
    }
    
    // TODO: Add actions
    private func accountActionItems() -> [ActionItem] {
        let actionItems = [
            ActionItem(iconName: "buy", label: "Buy", action: {
                path.append(.buy)
            }),
            ActionItem(iconName: "send", label: "Send", action: {
                guard let selectedAccount = viewModel.selectedAccount else { return }
                router?.showSendFundsFlow(selectedAccount)
            }),
            ActionItem(iconName: "receive", label: "Receive", action: {
                accountQr = (viewModel.selectedAccount as? AccountEntity)
//                path.append(.receive)
            }),
            ActionItem(iconName: "percent", label: "Earn", action: {
                
            }),
            ActionItem(iconName: "activity", label: "Activity", action: {
                
            })
        ]
        return actionItems
    }
}
