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
    @Published var isTransactionExecuting: Bool = true
    @Published var amountDisplay: String
    @Published var successTransactionText = ""
    @Published var failedTransactionText = ""
    @Published var inProgressTransactionText = ""
    @Published var shouldDisplayAmount: Bool = false
    @Published var isStopValidation: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertOptions: SwiftUIAlertOptions?
    
    let ticker: String = "CCD"
    private let transactionService: TransactionsServiceProtocol
    private let storageManager: StorageManagerProtocol
    private var cost: GTU?
    private var energy: Int?
    private var cancellables = Set<AnyCancellable>()
    private let passwordDelegate: RequestPasswordDelegate

    var transactionStatusLabel: String {
        withAnimation(.easeInOut(duration: 1)) {
            if isTransactionExecuting {
                return inProgressTransactionText
            } else if !isTransactionExecuting {
                return successTransactionText
            }
            if error != nil {
                return failedTransactionText
            }
            return ""
        }
    }
    
    init(dataHandler: BakerDataHandler,
         dependencyProvider: ServicesProvider) {
        self.transactionService = dependencyProvider.transactionsService()
        self.storageManager = dependencyProvider.storageManager()
        self.passwordDelegate = DummyRequestPasswordDelegate()
        self.amountDisplay = dataHandler.getCurrentAmount()?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
        super.init(dataHandler: dataHandler, account: dataHandler.account)
        setup(with: .init(dataHandler: dataHandler))
        getTransactionCost()
    }
    
    func setup(with type: BakerPoolReceiptType) {
        switch type {
        case .updateStake(_):
            successTransactionText = "validator.update.stake.success".localized
            failedTransactionText = "validator.update.stake.failed".localized
            inProgressTransactionText = "validator.update.stake.in.progress".localized
            shouldDisplayAmount = true
        case .updatePool:
            successTransactionText = "validator.update.pool.success".localized
            failedTransactionText = "validator.update.pool.failed".localized
            inProgressTransactionText = "validator.update.pool.in.progress".localized
            shouldDisplayAmount = false
        case .updateKeys:
            successTransactionText = "validator.update.keys.success".localized
            failedTransactionText = "validator.update.keys.failed".localized
            inProgressTransactionText = "validator.update.keys.in.progress".localized
            shouldDisplayAmount = false
        case .remove:
            successTransactionText = "validator.stop.success".localized
            failedTransactionText = "validator.stop.failed".localized
            inProgressTransactionText = "validator.stop.in.progress".localized
            shouldDisplayAmount = false
            isStopValidation = true
        case .register:
            successTransactionText = "validator.registered.success".localized
            failedTransactionText = "validator.registered.failed".localized
            inProgressTransactionText = "validator.registered.in.progress".localized
            shouldDisplayAmount = true
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
            withAnimation {
                showAlert = true
            }
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
            }).store(in: &cancellables)
    }
    
    private func stopValidationAlertOptions(completion: @escaping () -> Void) -> SwiftUIAlertOptions {
        let okAction = SwiftUIAlertAction(
            name: "baking.nochanges.ok".localized,
            completion: completion,
            style: .styled
        )
        return SwiftUIAlertOptions(
            title: "baking.nochanges.title".localized,
            message: storageManager.getChainParams().formattedPoolOwnerCooldown,
            actions: [okAction]
        )
    }
    
    func closeTapped(completion: @escaping () -> Void) {
        if !isTransactionExecuting && error == nil && isStopValidation {
            alertOptions = stopValidationAlertOptions(completion: completion)
            withAnimation {
                showAlert = true
            }
        } else {
            completion()
        }
    }
}

extension ValidatorSubmissionViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorSubmissionViewModel, rhs: ValidatorSubmissionViewModel) -> Bool {
        lhs.showAlert == rhs.showAlert &&
        lhs.account.address == rhs.account.address &&
        lhs.cost == rhs.cost &&
        lhs.energy == rhs.energy &&
        lhs.rows == rhs.rows
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(showAlert)
        hasher.combine(account.address)
        hasher.combine(cost)
        hasher.combine(energy)
        hasher.combine(rows)
    }
}

private extension Optional where Wrapped == ChainParametersEntity {
    var formattedPoolOwnerCooldown: String {
        let cooldown = GeneralFormatter.secondsToDays(seconds: self?.poolOwnerCooldown ?? 0)
        return String(format: "validation.stop.message".localized, cooldown)
    }
}
