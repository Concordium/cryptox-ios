//
//  StakeReceiptPresenter.swift
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

// MARK: -
// MARK: Presenter
protocol StakeReceiptPresenterProtocol: AnyObject {
	var view: StakeReceiptViewProtocol? { get set }
    func viewDidLoad()
    func pressedButton()
    func closeButtonTapped()
}
