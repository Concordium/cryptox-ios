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
        VStack(alignment: .leading, spacing: 16) {
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
                            .font(.satoshi(size: 13, weight: .light))
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
                    Text(viewModel.totalAmount.displayValue())
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 24, weight: .medium))
                    Image("ccd_logo_white_large")
                        .frame(width: 20, height: 20)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    Text(viewModel.totalAtDisposalAmount.displayValue())
                        .foregroundColor(Color.Neutral.tint7)
                        .font(.satoshi(size: 12, weight: .medium))
                    Text("accounts.atdisposal".localized)
                        .foregroundColor(Color.MineralBlue.tint2)
                        .font(.plexSans(size: 12, weight: .regular))
                }
            }
        }
    }
}

#Preview {
    AccountInfoView(viewModel: AccountPreviewViewModel(account: AccountEntity(name: "account", submissionId: "id", transactionStatus: .finalized, identity: IdentityEntity()), tokens: []))
}

