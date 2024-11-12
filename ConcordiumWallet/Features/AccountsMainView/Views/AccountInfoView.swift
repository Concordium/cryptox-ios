//
//  AccountInfoView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 30.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountInfoView: View {
    var viewModel: AccountPreviewViewModel
    
    var body: some View {
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
                        .font(.satoshi(size: 14, weight: .light))
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
                    Image("icon_validate")
                case .delegating:
                    Image("icon_delegate")
                case .basic: EmptyView()
                }
            }
            
            
            VStack(alignment: .leading ,spacing: 6) {
                HStack(spacing: 8) {
                    Text(viewModel.totalAmount)
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 24, weight: .medium))
                    Image("ccd_logo_white_large")
                        .frame(width: 20, height: 20)
                }
                HStack(spacing: 4) {
                    Text(viewModel.totalAtDisposalAmount)
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 16, weight: .medium))
                    Text("accounts.atdisposal".localized)
                        .foregroundColor(Color.MineralBlue.tint2)
                        .font(.plexSans(size: 14, weight: .regular))
                }
            }
            .padding(.top, 16)
            
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
                .padding(.top, 16)
            }
        }
        .padding(.top, (viewModel.tokens.isEmpty == false || viewModel.account.totalForecastBalance > 0) ? 16 :  0)
    }
}

#Preview {
    AccountInfoView(viewModel: AccountPreviewViewModel(account: AccountEntity(name: "account", submissionId: "id", transactionStatus: .finalized, identity: IdentityEntity()), tokens: []))
}
