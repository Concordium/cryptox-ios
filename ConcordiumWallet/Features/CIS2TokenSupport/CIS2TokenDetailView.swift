//
//  CIS2TokenDetailView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

final class CIS2TokenDetailViewModel: ObservableObject {
    let sceneTitle: String
    let tokenName: String
    let thumbnail: URL?
    let display: URL?
    let contractAddress: String
    let ticker: String
    let tokenId: String
    let description: String?
    let decimals: String
    
    @Published var balance: String = "0.0"

    var tokenBalance: CIS2TokenBalance?
    let account: AccountDataType
    let token: CIS2Token
    
    private let storageManager: StorageManagerProtocol
    private let networkManager: NetworkManagerProtocol
    private let cis2Service: CIS2Service
    private let onDismiss: () -> Void
    
    init(
        _ token: CIS2Token,
        account: AccountDataType,
        storageManager: StorageManagerProtocol,
        networkManager: NetworkManagerProtocol,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        self.storageManager = storageManager
        self.networkManager = networkManager
        self.token = token
        self.account = account
        self.sceneTitle = token.metadata.name ?? ""
        self.balance = "0.0"
        self.thumbnail = token.metadata.thumbnail?.url.toURL
        self.display = token.metadata.display?.url.toURL
        self.tokenName = token.metadata.name ?? ""
        self.contractAddress = "\(token.contractAddress.index),\(token.contractAddress.subindex)"
        self.ticker = token.metadata.symbol ?? ""
        self.tokenId = token.tokenId
        self.description = token.metadata.description
        self.decimals = "\(token.metadata.decimals ?? 0)"
        
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
    }
    
    @MainActor
    func reload() async {
        do {
            let balances = try await cis2Service.fetchTokensBalance(contractIndex: token.contractAddress.index.string, accountAddress: account.address, tokenId: token.tokenId)
            if let b = balances.first {
                self.balance = TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: b.balance), token.metadata.decimals ?? 0), decimalSeparator: ".", thousandSeparator: ",")
            }
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
    
    func removeToken() {
        do {
            try storageManager.removeCIS2Token(token: token, address: account.address)
            self.onDismiss()
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}

struct CIS2TokenDetailView: View {
    @StateObject var viewModel: CIS2TokenDetailViewModel
    @EnvironmentObject var router: AccountDetailRouter
    
    @State private var showingQR = false
    @State var showRemoveTokenButton = true
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x242427), Color(hex: 0x09090B)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack {
                        TokenPreviewHeaderView()
                            .cornerRadius(24, corners: .allCorners)
                        
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(viewModel.tokenName)
                                    .foregroundColor(Color.white)
                                    .font(.satoshi(size: 15, weight: .medium))
                                CryptoImage(url: viewModel.display ?? viewModel.thumbnail, size: .custom(width: 300, height: 300))
                                    .aspectRatio(contentMode: .fit)
                                
                            }
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("cis2token_detail_contract_address_title".localized)
                                        .foregroundColor(Color.blackAditional)
                                        .font(.satoshi(size: 14, weight: .medium))
                                    Text(viewModel.contractAddress)
                                        .foregroundColor(Color.white)
                                        .font(.satoshi(size: 14, weight: .medium))
                                }
                                VerticalLine().background(Color.greyMain).opacity(0.2).padding(.vertical, 8)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Symbol")
                                        .foregroundColor(Color.blackAditional)
                                        .font(.satoshi(size: 14, weight: .medium))
                                    Text(viewModel.ticker)
                                        .foregroundColor(Color.white)
                                        .font(.satoshi(size: 14, weight: .medium))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8){
                                if !viewModel.tokenId.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Token ID".localized)
                                            .foregroundColor(Color.blackAditional)
                                            .font(.satoshi(size: 14, weight: .medium))
                                        Text(viewModel.tokenId)
                                            .foregroundColor(Color.white)
                                            .font(.satoshi(size: 14, weight: .medium))
                                    }
                                }
                                
                                if let description = viewModel.description {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Description".localized)
                                            .foregroundColor(Color.blackAditional)
                                            .font(.satoshi(size: 14, weight: .medium))
                                        Text(description)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(Color.white)
                                            .font(.satoshi(size: 14, weight: .medium))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Decimals")
                                        .foregroundColor(Color.blackAditional)
                                        .font(.satoshi(size: 14, weight: .medium))
                                    Text(viewModel.decimals)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(Color.white)
                                        .font(.satoshi(size: 14, weight: .medium))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                        .overlay(
                            RoundedCorner(radius: 24, corners: .allCorners)
                                .stroke(Color.blackSecondary, lineWidth: 1)
                        )
                    }
                    .padding(16)
                }
                .clipped()
            }
        }
        .onAppear { Task { await viewModel.reload() } }
        .refreshable {
            Task { await viewModel.reload() }
        }
        .navigationTitle(viewModel.sceneTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showRemoveTokenButton {
                    Menu(content: {
                        Button("token_detail_remove_token_action_title".localized, action: viewModel.removeToken)
                    }, label: { Image("ico_menu") })
                }
            }
        }
        .sheet(isPresented: $showingQR) {
            AccountQRView(account: viewModel.account)
        }
    }
    
    private func TokenPreviewHeaderView() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                Text(viewModel.balance)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 19, weight: .medium))
                CryptoImage(url: viewModel.thumbnail, size: .small)
                    .aspectRatio(contentMode: .fit)
            }
            Text("accountDetails.generalbalance".localized)
                .foregroundColor(Color.greySecondary)
                .font(.satoshi(size: 15, weight: .medium))
            
            Divider().background(Color.greyMain.opacity(0.2))
                .padding(.top, 12)
                .padding(.horizontal, -20)
            HStack {
                HStack {
                    Spacer()
                    Image("icon_transfer")
                        .renderingMode(.template)
                        .tint(Color.white)
                        .frame(width: 17, height: 17)
                    Spacer()
                }.contentShape(Rectangle())
                    .onTapGesture {
                        self.router.showSendTokenFlow(tokenType: .cis2(viewModel.token))
                    }

                VerticalLine()
                    .background(Color.greyMain)
                    .opacity(0.2)
                    .frame(width: 1)
                
                HStack {
                    Spacer()
                    Image("icon_scan")
                        .renderingMode(.template)
                        .tint(Color.white)
                        .frame(width: 17, height: 17)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingQR.toggle()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(Color.blackSecondary)
    }
}
