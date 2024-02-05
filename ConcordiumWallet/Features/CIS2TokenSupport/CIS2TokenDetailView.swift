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
    let contractAddress: String
    let ticker: String
    
    @Published var balance: String = "0.0"

    var tokenBalance: CIS2TokenBalance?
    let account: AccountDataType
    let token: CIS2Token
    
    private let storageManager: StorageManagerProtocol
    private let onPop: () -> Void
    
    init(
        _ token: CIS2Token,
        account: AccountDataType,
        storageManager: StorageManagerProtocol,
        onPop: @escaping () -> Void
    ) {
        self.onPop = onPop
        self.storageManager = storageManager
        self.token = token
        self.account = account
        self.sceneTitle = token.metadata.name ?? ""
        self.balance = "0.0"
        self.thumbnail = token.metadata.thumbnail?.url.toURL
        self.tokenName = token.metadata.name ?? ""
        self.contractAddress = "\(token.contractAddress.index),\(token.contractAddress.subindex)"
        self.ticker = token.metadata.symbol ?? ""
    }
    
    @MainActor
    func reload() async {
        do {
            let balances = try await CIS2TokenService.getCIS2TokenBalance(index: token.contractAddress.index, tokenIds: [token.tokenId], address: account.address)
            if let b = balances.first {
                self.balance = TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: b.balance), token.metadata.decimals ?? 0))
            }
        } catch {
            
        }
    }
    
    func removeToken() {
        do {
            try storageManager.removeCIS2Token(token: token, address: account.address)
            self.onPop()
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}

struct CIS2TokenDetailView: View {
    @StateObject var viewModel: CIS2TokenDetailViewModel
    @EnvironmentObject var router: AccountDetailRouter
    
    @State private var showingQR = false

    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x242427), Color(hex: 0x09090B)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                List {
                    VStack(alignment: .leading) {
                        HStack(spacing: 8) {
                            Text(viewModel.balance)
                                .foregroundColor(.white)
                                .font(.system(size: 19, weight: .medium))
                            CryptoImage(url: viewModel.thumbnail, size: .small)
                                .aspectRatio(contentMode: .fit)
                        }
                        Text("accountDetails.generalbalance".localized)
                            .foregroundColor(Color.greySecondary)
                            .font(.system(size: 15, weight: .medium))
                        
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
//                                self.router.showAccountAddressQR(viewModel.account)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blackSecondary)
                    .cornerRadius(24, corners: .allCorners)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 8) {
                            CryptoImage(url: viewModel.thumbnail, size: .small)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18, alignment: .center)
                            Text(viewModel.tokenName)
                                .foregroundColor(Color.white)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                        }
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("cis2token_detail_contract_address_title".localized)
                                    .foregroundColor(Color.blackAditional)
                                    .font(.system(size: 14, weight: .medium))
                                Text(viewModel.contractAddress)
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            VerticalLine().background(Color.greyMain).opacity(0.2).padding(.vertical, 8)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("token".localized)
                                    .foregroundColor(Color.blackAditional)
                                    .font(.system(size: 14, weight: .medium))
                                Text(viewModel.ticker)
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 14, weight: .medium))
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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

            }
        }
        .listStyle(.plain)
        .onAppear { Task { await viewModel.reload() } }
        .refreshable {
            Task { await viewModel.reload() }
        }
        .navigationTitle(viewModel.sceneTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu(content: {
                    Button("token_detail_remove_token_action_title".localized, action: viewModel.removeToken)
                }, label: { Image("ico_menu") })
                
            }
        }
        .sheet(isPresented: $showingQR) {
            AccountQRView(account: viewModel.account)
        }
    }
}
