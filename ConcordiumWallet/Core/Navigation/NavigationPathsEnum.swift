//
//  NavigationPathsEnum.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum NavigationPaths: Hashable {
    case accountsOverview
    case manageTokens
    case tokenDetails(token: AccountDetailAccount)
    case buy
    case send
    case earn
    case activity
    case addToken
    case addTokenDetails(token: AccountDetailAccount)
    case transactionDetails(transaction: TransactionDetailViewModel)
    case chooseTokenToSend(transferTokenVM: TransferTokenViewModel)
    case selectRecipient
    case confirmTransaction(_ vm: TransferTokenViewModel)
    case transferSendingStatus(_ vm: TransferTokenConfirmViewModel)
}
