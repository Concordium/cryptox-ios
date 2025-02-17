//
//  NavigationPathsEnum.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum NavigationPaths: Hashable {
    case accountsOverview(_ viewModel: AccountsMainViewModel)
    case manageTokens(_ viewModel: AccountsMainViewModel)
    case tokenDetails(token: AccountDetailAccount, _ viewModel: AccountDetailViewModel)
    case buy
    case send(_ account: AccountEntity)
    case receive(_ account: AccountEntity)
    case activity(_ account: AccountEntity)
    case addToken(_ account: AccountEntity)
    case addTokenDetails(token: AccountDetailAccount)
    case transactionDetails(transaction: TransactionDetailViewModel)
    case chooseTokenToSend(transferTokenVM: TransferTokenViewModel, _ viewModel: AccountDetailViewModel)
    case selectRecipient(_ account: AccountEntity, mode: SelectRecipientMode)
    case confirmTransaction(_ vm: TransferTokenViewModel)
    case transferSendingStatus(_ vm: TransferTokenConfirmViewModel)
    case addRecipient(mode: EditRecipientMode)
    case earn(_ account: AccountEntity)
    case earnMain(_ account: AccountEntity)
    case earnReadMode(mode: EarnMode, account: AccountEntity)
    case earnAmountInputView(_ vm: StakeAmountInputViewModel)
    // MARK: - Validator Flow
    case validator(ValidatorNavigationPaths, account: AccountEntity)
}

enum ValidatorNavigationPaths: Equatable, Hashable {
    case validatorFlow(_ account: AccountEntity)
    case status(BakerPoolStatus)
//    case menu(currentSettings: BakerEntity, poolInfo: PoolInfo)
    case learnAbout(BakerDataHandler)
//    case poolSettings(BakerDataHandler)
//    case generateKey(BakerDataHandler)
//    case metadataUrl(BakerDataHandler)
//    case commissionSettings(BakerDataHandler)
//    case amountInput(BakerDataHandler)
//    case requestConfirmation(BakerDataHandler)
//    case submissionReceipt(TransferEntity, StakeDataHandler)
}
