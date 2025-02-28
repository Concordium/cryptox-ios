//
//  ValidatorSubmissionViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class ValidatorSubmissionViewModel: StakeReceiptViewModel, ObservableObject {
    @Published var error: Error?
    @Published var showFeeAlert: Bool = false
    @Published var isTransactionExecuting: Bool = true
    @Published var transferDataType: TransferDataType?
    @Published var amountDisplay: String
    
    let ticker: String = "CCD"
    private let transactionService: TransactionsServiceProtocol
    private let storageManager: StorageManagerProtocol
    private var cost: GTU?
    private var energy: Int?
    private var cancellables = Set<AnyCancellable>()
    private let account: AccountDataType
    private let passwordDelegate: RequestPasswordDelegate

    var transactionStatusLabel: String {
        withAnimation(.easeInOut(duration: 1)) {
            if isTransactionExecuting {
                return "validator.registered.in.progress".localized
            } else if !isTransactionExecuting {
                return "validator.registered.success".localized
            }
            if error != nil {
                return "validator.registered.failed".localized
            }
            return ""
        }
    }
    
    init(dataHandler: BakerDataHandler,
         dependencyProvider: ServicesProvider) {
        self.account = dataHandler.account
        self.transactionService = dependencyProvider.transactionsService()
        self.storageManager = dependencyProvider.storageManager()
        self.passwordDelegate = DummyRequestPasswordDelegate()
        self.amountDisplay = dataHandler.getCurrentAmount()?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
        super.init(dataHandler: dataHandler)
        setup(with: .init(dataHandler: dataHandler))
        getTransactionCost()
    }
    
    func setup(with type: BakerPoolReceiptType) {
        receiptFooterText = nil
        showsSubmitted = false
        buttonLabel = "baking.receiptconfirmation.submit".localized
        
        switch type {
        case let .updateStake(isLoweringStake):
            title = "baking.receiptconfirmation.title.updatestake".localized
            receiptHeaderText = "baking.receiptconfirmation.updatebakerstake".localized
            if isLoweringStake {
                text = "baking.receiptconfirmation.loweringstake".localized
            } else {
                text = nil
            }
        case .updatePool:
            title = "baking.receiptconfirmation.title.updatepool".localized
            receiptHeaderText = "baking.receiptconfirmation.updatebakerpool".localized
            text = nil
        case .updateKeys:
            title = "baking.receiptconfirmation.title.updatekeys".localized
            receiptHeaderText = "baking.receiptconfirmation.updatebakerkeys".localized
            text = nil
        case .remove:
            title = "baking.receiptconfirmation.title.remove".localized
            text = "baking.receiptconfirmation.removetext".localized
            receiptHeaderText = "baking.receiptconfirmation.stopbaking".localized
        case .register:
            title = "baking.receiptconfirmation.title.register".localized
            text = "baking.receiptconfirmation.registertext".localized
            receiptHeaderText = "baking.receiptconfirmation.registerbaker".localized
        }
    }
    
    func getTransactionCost() {
        transactionService
            .getTransferCost(
                transferType: dataHandler.transferType.toWalletProxyTransferType(),
                costParameters: dataHandler.getCostParameters()
            )
            .sink { [weak self] error in
                self?.error = ErrorMapper.toViewError(error: error)
            } receiveValue: { [weak self] transferCost in
                let cost = GTU(intValue: Int(transferCost.cost) ?? 0)
                self?.cost = cost
                self?.energy = transferCost.energy
                self?.transactionFeeText = cost.displayValueWithCCDStroke()
                self?.rows.append(StakeRowViewModel(displayValue: DisplayValue(key: "estimated.tx.fee".localized, value: self?.transactionFeeText ?? "")))
                self?.displayFeeWarningIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func displayFeeWarningIfNeeded() {
        let atDisposal = GTU(intValue: account.forecastAtDisposalBalance)
        if let cost = cost, cost > atDisposal {
            showFeeAlert = true
        }
    }
    
    func pressedButton() {
        guard let cost = cost, let energy = energy else {
            return
        }
        isTransactionExecuting = true
        error = nil
        let transfer = dataHandler.getTransferObject(cost: cost, energy: energy)
        
        self.transactionService.performTransfer(
            transfer,
            from: account,
            bakerKeys: dataHandler.getNewEntry(BakerKeyData.self)?.keys,
            requestPasswordDelegate: passwordDelegate
        )
            .tryMap(self.storageManager.storeTransfer(_:))
            .sink(receiveError: { error in
                if !GeneralError.isGeneralError(.userCancelled, error: error) {
                    self.error = ErrorMapper.toViewError(error: error)
                    self.isTransactionExecuting = false
                }
            }, receiveValue: { transfer in
                self.transferDataType = transfer
                self.isTransactionExecuting = false
//                self.delegate?.confirmedTransaction(transfer: transfer, dataHandler: self.dataHandler)
            }).store(in: &cancellables)
    }
}

extension ValidatorSubmissionViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorSubmissionViewModel, rhs: ValidatorSubmissionViewModel) -> Bool {
        lhs.showFeeAlert == rhs.showFeeAlert &&
        lhs.account.address == rhs.account.address &&
        lhs.cost == rhs.cost &&
        lhs.energy == rhs.energy &&
        lhs.rows == rhs.rows
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(showFeeAlert)
        hasher.combine(account.address)
        hasher.combine(cost)
        hasher.combine(energy)
        hasher.combine(rows)
    }
}
