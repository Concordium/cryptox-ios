//
//  AccountPreviewViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

final class AccountPreviewViewModel: Identifiable {
    var totalAmount: GTU
    var totalAtDisposalAmount: GTU
    
    var accountName: String
    var accountOwner: String
    var isInitialAccount: Bool
    
    var viewState: AccountCardViewState = .basic
    
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
        
        if account.baker != nil {
            viewState = .baking
        } else if account.delegation != nil {
            viewState = .delegating
        } else if account.isReadOnly {
            viewState = .readonly
        }
    }
}
