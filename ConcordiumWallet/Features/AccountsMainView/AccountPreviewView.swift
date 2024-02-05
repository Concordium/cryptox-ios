//
//  AccountPreviewView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum AccountCardViewState {
    case basic
    case readonly
    case baking
    case delegating
}

final class AccountPreviewViewModel: Identifiable {
    var totalAmount: String
    var totalAtDisposalAmount: String
    
    var accountName: String
    var accountOwner: String
    var isInitialAccount: Bool
    
    var viewState: AccountCardViewState = .basic
    
    var id: Int {
        account.address.hashValue
        ^ tokens.count
        ^ account.totalForecastBalance.hashValue
        ^ account.transactionStatus.hashValue
        ^ account.forecastAtDisposalBalance.hashValue
        ^ account.finalizedBalance.hashValue
        ^ account.forecastBalance.hashValue
        ^ account.forecastEncryptedBalance.hashValue
    }
    
    let account: AccountDataType
    @Published var tokens: [CIS2Token] = []
    
    init(account: AccountDataType, tokens: [CIS2Token]) {
        self.account = account
        self.tokens = tokens
        
        self.totalAmount = GTU(intValue: account.totalForecastBalance).displayValue()
        self.totalAtDisposalAmount = GTU(intValue: account.forecastAtDisposalBalance).displayValue()
        
        self.accountName = account.displayName
        self.accountOwner = account.identity?.nickname ?? ""
        self.isInitialAccount = account.credential?.value.credential.type == "initial"
        
        if account.baker != nil {
            viewState = .baking
        } else if account.delegation != nil {
            viewState = .delegating
        } else if account.isReadOnly {
            viewState = .readonly
        }
    }
}

struct AccountPreviewView: View {
    var viewModel: AccountPreviewViewModel
    
    var onQrTap: () -> Void
    var onSendTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                HStack {
                    Text(viewModel.accountName)
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 16, weight: .medium))
                    Text(viewModel.accountOwner)
                        .foregroundColor(Color.MineralBlue.tint2)
                        .font(.plexSans(size: 14, weight: .regular))
                    if viewModel.isInitialAccount {
                        Text("accounts.initial".localized)
                            .foregroundColor(.blackAditional)
                            .font(.system(size: 14, weight: .light))
                    }
                    switch viewModel.account.transactionStatus {
                        case .absent:
                            Image("problem_icon").resizable().frame(width: 16, height: 16)
                        case .received, .committed:
                            Image("pending").resizable().frame(width: 16, height: 16)
                        default: EmptyView()
                    }
                    Spacer()
                    switch viewModel.viewState {
                        case .readonly:
                            HStack {
                                Text("accounts.overview.readonly".localized)
                                    .foregroundColor(.blackAditional)
                                    .font(.system(size: 13, weight: .light))
                                Image("icon_read_only")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                        case .baking:
                            HStack {
                                Text("accounts.overview.baking".localized)
                                    .foregroundColor(.blackAditional)
                                    .font(.system(size: 13, weight: .light))
                                Image("icon_bread")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                        case .delegating:
                            HStack {
                                Text("accounts.overview.delegating".localized)
                                    .foregroundColor(.blackAditional)
                                    .font(.system(size: 13, weight: .light))
                                Image("icon_delegate").resizable().frame(width: 16, height: 16)
                            }
                        case .basic: EmptyView()
                    }
                }
                
//                Divider()
                
                VStack(alignment: .leading ,spacing: 10) {
//                    HStack(spacing: 7) {
//                        Text(viewModel.totalAmount)
//                            .foregroundColor(Color.deepBlue)
//                            .font(.system(size: 30, weight: .bold))
//                        Image("ccd_logo_white_large")
//                    }
                    Text(viewModel.totalAmount)
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 24, weight: .medium))
                        .overlay(alignment: .bottomTrailing) {
                            Text("CCD")
                                .foregroundColor(Color.Neutral.tint5)
                                .font(.satoshi(size: 12, weight: .regular))
                                .offset(x: 26, y: -4)
                        }
                    HStack(spacing: 4) {
                        Text("accounts.atdisposal".localized)
                            .foregroundColor(Color.MineralBlue.tint2)
                            .font(.plexSans(size: 14, weight: .regular))
                        Text(viewModel.totalAtDisposalAmount)
                            .foregroundColor(Color.Neutral.tint7)
                            .font(.satoshi(size: 16, weight: .medium))
                            .overlay(alignment: .bottomTrailing) {
                                Text("CCD")
                                    .foregroundColor(Color.Neutral.tint5)
                                    .font(.satoshi(size: 12, weight: .regular))
                                    .offset(x: 26)
                            }
//                        Image("ccd_logo_white_large").resizable().frame(width: 16, height: 16)
                    }
                }
                
                let hasCCD = viewModel.account.totalForecastBalance > 0
                if viewModel.tokens.isEmpty == false || hasCCD {
                    let tokensTotal = viewModel.tokens.count + (hasCCD ? 1 : 0)
                    HStack {
                        Text("connected_token".localized)
                            .foregroundColor(Color.MineralBlue.tint2)
                            .font(.plexSans(size: 14, weight: .regular))
                        Spacer()
                        HStack(spacing: 6) {
                            if hasCCD {
                                Image("ccd_logo_white_large").resizable().frame(width: 24, height: 24)
                            }
                            ForEach(viewModel.tokens.prefix(4 - (hasCCD ? 1 : 0))) { token in
                                CryptoImage(url: (token.metadata.thumbnail?.url ?? "").toURL, size: .custom(width: 24, height: 24))
                                    .background(Color.white)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                                            .frame(width: 24, height: 24)
                                    )
                                    .clipShape(Circle())
                            }
                        }
                        
                        if tokensTotal > 4 {
                            Circle()
                                .strokeBorder(.black.opacity(0.08), lineWidth: 1)
                                .background(Circle().foregroundColor(Color.white))
                                .frame(width: 24, height: 24)
                                .overlay(alignment: .center) {
                                    Text("+\(tokensTotal - viewModel.tokens.prefix(4).count)")
                                        .foregroundColor(Color.blackSecondary)
                                        .font(.system(size: 12, weight: .medium))
                                }
                        }
                    }
                    .background(Color.clear)
                    .padding(.top, 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(.white.opacity(0.63))
            .background(
                EllipticalGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.62, green: 0.95, blue: 0.92), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.93, green: 0.85, blue: 0.75), location: 0.27),
                        Gradient.Stop(color: Color(red: 0.62, green: 0.6, blue: 0.71), location: 1.00),
                    ],
                    center: UnitPoint(x: 0.09, y: 0.18)
                )
            )
            
            if viewModel.account.isReadOnly == false {
                HStack {
                    Button {
                        self.onSendTap()
                    } label: {
                        Image("ico_share")
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(BorderlessButtonStyle())
//                    .background(Color.blackSecondary)
                   
                    Divider().padding(.vertical, 11)

                    Button {
                        self.onQrTap()
                    } label: {
                        Image("ico_qr")
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(BorderlessButtonStyle())
//                    .background(Color.blackSecondary)
                }
                .background(Color.Neutral.tint5)
            }
        }
        .cornerRadius(24, corners: .allCorners)
        .listSectionSeparator(.hidden)
    }
    
    
//    private let pipeline = ImagePipeline {
//        $0.dataLoader = {
//            let config = URLSessionConfiguration.default
//            config.urlCache = nil
//            return DataLoader(configuration: config)
//        }()
//    }
}
