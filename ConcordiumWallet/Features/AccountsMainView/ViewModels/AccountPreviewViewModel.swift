//
//  AccountPreviewViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import RealmSwift

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
    
    @Published var tokens: [CIS2Token] = []

    private let accountAddress: String
    
    var account: AccountEntity? {
        try? Realm().object(ofType: AccountEntity.self, forPrimaryKey: accountAddress)
    }
    
    var id: Int {
        let addressHash = accountAddress.hashValue
        let tokenCountHash = tokens.count
        let forecastBalanceHash = account?.totalForecastBalance.hashValue ?? 0
        let transactionStatusHash = account?.transactionStatus.hashValue ?? 0
        let disposalBalanceHash = account?.forecastAtDisposalBalance.hashValue ?? 0
        let finalizedBalanceHash = account?.finalizedBalance.hashValue ?? 0
        let forecastHash = account?.forecastBalance.hashValue ?? 0
        let encryptedBalanceHash = account?.forecastEncryptedBalance.hashValue ?? 0
        
        return addressHash
            ^ tokenCountHash
            ^ forecastBalanceHash
            ^ transactionStatusHash
            ^ disposalBalanceHash
            ^ finalizedBalanceHash
            ^ forecastHash
            ^ encryptedBalanceHash
    }

    init(account: AccountDataType, tokens: [CIS2Token]) {
        self.accountAddress = account.address
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
