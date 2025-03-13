//
//  NavigationPathsEnum.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import SwiftUI

enum NavigationPaths: Hashable {
    case accountsOverview(_ viewModel: AccountsMainViewModel)
    case manageTokens(_ viewModel: AccountsMainViewModel)
    case tokenDetails(token: AccountDetailAccount, _ viewModel: AccountDetailViewModel)
    case buy
    case send(_ account: AccountEntity, tokenType: CXTokenType)
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
    // MARK: - Validator Flow
    case generateKey(ValidatorGenerateKeysViewModel)
    case metadataUrl(ValidatorMetadataViewModel)
    case commissionSettings(ValidatorCommissionSettingsViewModel)
    case amountInput(ValidatorAmountInputViewModel)
    case openningPool(ValidatorPoolSettingsViewModel)
    case validatorRequestConfirmation(ValidatorSubmissionViewModel)
    case validatorTransactionStatus(ValidatorSubmissionViewModel)
    case validatorStatus(ValidatorStakeStatusViewModel)
    case updateValidatorMenu(ValidatorUpdateMenuViewModel)
    // MARK: - Delegation Flow
    case delegationAmountInput(DelegationAmountInputViewModel)
    case delegationStakingMode(DelegationStakingModeViewModel)
    case delegationRequestConfirmation(DelegationSubmissionViewModel)
    case delegationTransactionStatus(DelegationSubmissionViewModel)
}
