//
//  AccountDetailView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 24.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class AccountDetailViewModel: ObservableObject {
    @Published var accountState: SubmissionStatusEnum = .committed
    
    @Published var sceneTitle: String = ""
    @Published var balance: String = "0.001"
    @Published var atDisposal: String = "0.01"
    @Published var isShieldedEnabled: Bool = true
    @Published var isShielded = false
    @Published var hasStaked: Bool = false
    @Published var stakeViewIsHidden: Bool = true
    @Published var areActionsEnabled = false
    @Published var isReadOnly = false
    
    @Published var stakedLabelText: String?
    @Published var stakedValue: String = ""
    
    init() {}
    
    
    init(account: AccountDataType, balanceType: AccountBalanceTypeEnum) {
        accountState = account.transactionStatus ?? .committed
        atDisposal = GTU(intValue: account.forecastAtDisposalBalance).displayValue()
        isShieldedEnabled = account.showsShieldedBalance
        isShielded = balanceType == .shielded
        isReadOnly = account.isReadOnly
        areActionsEnabled = accountState == .finalized && !isReadOnly
        sceneTitle = account.displayName
        
        switch balanceType {
            case .total:
                balance = GTU(intValue: account.forecastBalance).displayValue()
            case .balance:
                balance = GTU(intValue: account.forecastBalance).displayValue()
            case .shielded:
                balance = GTU(intValue: account.forecastEncryptedBalance).displayValue()
        }
        
        updateStaked(account: account, balanceType: balanceType)
    }
    
    private func updateStaked(account: AccountDataType, balanceType: AccountBalanceTypeEnum) {
        switch balanceType {
            case .shielded:
                hasStaked = false
                stakeViewIsHidden = true
            default:
                if let baker = account.baker, baker.bakerID != -1 {
                    self.hasStaked = true
                    stakeViewIsHidden = false
                    stakedLabelText = String(format: "accountDetails.bakingstakelabel".localized, String(baker.bakerID))
                    self.stakedValue = GTU(intValue: baker.stakedAmount ).displayValueWithGStroke()
                } else if let delegation = account.delegation {
                    let pool = BakerTarget.from(delegationType: delegation.delegationTargetType, bakerId: delegation.delegationTargetBakerID)
                    
                    self.hasStaked = true
                    stakeViewIsHidden = false
                    stakedLabelText = pool.getDisplayValueForAccountDetails()
                    self.stakedValue = GTU(intValue: Int(delegation.stakedAmount) ).displayValueWithGStroke()
                    
                } else {
                    self.hasStaked = false
                    stakeViewIsHidden = true
                    stakedLabelText = nil
                }
        }
    }
}

extension BakerTarget {
    fileprivate func getDisplayValueForAccountDetails() -> String {
        switch self {
            case .passive:
                return "accountDetails.passivevalue".localized
            case .bakerPool(let bakerId):
                return String(format: "accountDetails.bakerpoolvalue".localized, bakerId)
        }
    }
}


struct AccountDetailView: View {
    @EnvironmentObject var viewModel: AccountDetailViewModel
    @EnvironmentObject var proxy: AccountDetailProxy

    var body: some View {
        VStack {
            AccountHeaderView(
                balance: viewModel.balance,
                disposalAmount: viewModel.atDisposal,
                stakedValue: viewModel.stakedValue,
                stakedLabelText: viewModel.stakedLabelText ?? "",
                stakeViewIsHidden: viewModel.stakeViewIsHidden,
                isShielded: viewModel.isShielded,
                isReadOnly: viewModel.isReadOnly
            )
            Spacer()
        }
        .navigationTitle(viewModel.sceneTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    proxy.showSettings()
                } label: {
                    Image("ico_settings")
                }
            }
        }
    }
}

struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AccountDetailView().environmentObject(AccountDetailViewModel())
    }
}

struct BalanceView: View {
    var balance: String
    
    var body: some View {
        HStack {
            Text(balance)
                .foregroundColor(.white)
                .font(.system(size: 19, weight: .medium))
                .multilineTextAlignment(.leading)
            Text("CCD")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .multilineTextAlignment(.center)
                .background(Color.init(hex: 0xA9AEB9).opacity(0.4))
                .clipShape(Capsule())
        }
    }
}


struct BalanceView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceView(balance: "0.001")
    }
}

struct AccountHeaderView: View {
    let balance: String
    let disposalAmount: String
    let stakedValue: String
    let stakedLabelText: String
    let stakeViewIsHidden: Bool
    let isShielded: Bool
    let isReadOnly: Bool
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        BalanceView(balance: balance)
                        Text("accounts.overview.generaltotal".localized)
                            .foregroundColor(.greySecondary)
                            .font(.system(size: 15, weight: .medium))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        BalanceView(balance: disposalAmount)
                        Text("accounts.totalatdisposal".localized)
                            .foregroundColor(.greySecondary)
                            .font(.system(size: 15, weight: .medium))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                /// Delegation / staking / smth else
                if !stakeViewIsHidden  {
                    VStack {
                        Divider()
                        HStack {
                            VStack(alignment: .leading) {
                                BalanceView(balance: stakedValue)
                                Text(stakedLabelText)
                                    .foregroundColor(.greySecondary)
                                    .font(.system(size: 15, weight: .medium))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(24)
            
            AccountActionButtons(
                isShielded: isShielded,
                actionSend: {},
                actionReceive: {},
                actionEarn: {},
                actionShield: {},
                actionSettings: {},
                disabled: isReadOnly
            )
        }
        .background(Color.blackSecondary)
        .clipShape(RoundedCorner(radius: 24, corners: .allCorners))
    }
}
