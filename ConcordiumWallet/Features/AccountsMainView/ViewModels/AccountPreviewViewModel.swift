//
//  AccountPreviewViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

final class AccountPreviewViewModel: Identifiable, Equatable {
    var totalAmount: GTU
    var totalAtDisposalAmount: GTU
    
    var accountName: String
    var accountOwner: String
    var isInitialAccount: Bool
    
    var stakedAmount: GTU
    
    var viewState: AccountCardViewState = .basic
    
    var dotImageIndex: Int = 1
    let address: String
    
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
        self.address = account.address
        
        self.totalAmount = GTU(intValue: account.totalForecastBalance)
        self.totalAtDisposalAmount = GTU(intValue: account.forecastAtDisposalBalance)
        
        self.accountName = account.displayName
        self.accountOwner = account.identity?.nickname ?? ""
        self.isInitialAccount = account.credential?.value.credential.type == "initial"
        
        self.stakedAmount = GTU(intValue: account.baker?.stakedAmount ?? account.delegation?.stakedAmount ?? 0)
        
        if account.baker != nil {
            viewState = .baking
        } else if account.delegation != nil {
            viewState = .delegating
        } else if account.isReadOnly {
            viewState = .readonly
        }
    }
    
    static func == (lhs: AccountPreviewViewModel, rhs: AccountPreviewViewModel) -> Bool {
        return lhs.totalAmount == rhs.totalAmount &&
        lhs.totalAtDisposalAmount == rhs.totalAtDisposalAmount &&
        lhs.accountName == rhs.accountName &&
        lhs.accountOwner == rhs.accountOwner &&
        lhs.address == rhs.address
    }
}
