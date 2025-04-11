//
//  StakeReceiptViewModel.swift
//  ConcordiumWallet
//
//  Created by Ruxandra Nistor on 11/03/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

class StakeReceiptViewModel {
    @Published var title: String = ""
    @Published var text: String?
    @Published var receiptHeaderText: String = ""
    @Published var transactionFeeText: String = ""
    @Published var receiptFooterText: String?
    @Published var transferDataType: TransferDataType?

    @Published var showsSubmitted: Bool = false
    @Published var showsBackButton: Bool = true
    @Published var buttonLabel: String = ""
    @Published var rows: [StakeRowViewModel]

    @Published var error: Error?
    @Published var isTransactionExecuting: Bool = true
    @Published var amountDisplay: String = ""
    @Published var successTransactionText = ""
    @Published var failedTransactionText = ""
    @Published var inProgressTransactionText = ""
    @Published var shouldDisplayAmount: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertOptions: SwiftUIAlertOptions?
    @Published var sliderButtonText: String = ""
    
    let dataHandler: StakeDataHandler
    let account: AccountDataType

    init(dataHandler: StakeDataHandler, account: AccountDataType) {
        self.dataHandler = dataHandler
        self.account = account
        rows = dataHandler.getAllOrdered().map { StakeRowViewModel(displayValue: $0) }
    }
    
    func getTransactionViewModel() -> TransactionViewModel? {
        guard let transferDataType else { return nil }
        let viewModel = TransactionViewModel(localTransferData: transferDataType, submissionStatus: nil, account: account, balanceType: .balance) { _ in
            return nil
        } recipientListLookup: { _ in
            return nil
        }
        return viewModel
    }
}

extension StakeReceiptViewModel: Equatable, Hashable {
    static func == (lhs: StakeReceiptViewModel, rhs: StakeReceiptViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.text == rhs.text &&
        lhs.receiptHeaderText == rhs.receiptHeaderText &&
        lhs.transactionFeeText == rhs.transactionFeeText &&
        lhs.receiptFooterText == rhs.receiptFooterText &&
        lhs.transferDataType?.params == rhs.transferDataType?.params &&
        lhs.showsSubmitted == rhs.showsSubmitted &&
        lhs.showsBackButton == rhs.showsBackButton &&
        lhs.buttonLabel == rhs.buttonLabel &&
        lhs.rows == rhs.rows &&
        lhs.error?.localizedDescription == rhs.error?.localizedDescription &&
        lhs.isTransactionExecuting == rhs.isTransactionExecuting &&
        lhs.amountDisplay == rhs.amountDisplay &&
        lhs.successTransactionText == rhs.successTransactionText &&
        lhs.failedTransactionText == rhs.failedTransactionText &&
        lhs.inProgressTransactionText == rhs.inProgressTransactionText &&
        lhs.shouldDisplayAmount == rhs.shouldDisplayAmount &&
        lhs.showAlert == rhs.showAlert &&
        lhs.alertOptions?.message == rhs.alertOptions?.message &&
        lhs.sliderButtonText == rhs.sliderButtonText
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(text)
        hasher.combine(receiptHeaderText)
        hasher.combine(transactionFeeText)
        hasher.combine(receiptFooterText)
        hasher.combine(transferDataType?.params)
        hasher.combine(showsSubmitted)
        hasher.combine(showsBackButton)
        hasher.combine(buttonLabel)
        hasher.combine(rows)
        hasher.combine(error?.localizedDescription)
        hasher.combine(isTransactionExecuting)
        hasher.combine(amountDisplay)
        hasher.combine(successTransactionText)
        hasher.combine(failedTransactionText)
        hasher.combine(inProgressTransactionText)
        hasher.combine(shouldDisplayAmount)
        hasher.combine(showAlert)
        hasher.combine(alertOptions?.message)
        hasher.combine(sliderButtonText)
    }
}
