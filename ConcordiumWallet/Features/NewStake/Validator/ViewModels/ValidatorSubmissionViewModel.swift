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
    @Published var isStopValidation: Bool = false
    @Published var isResumeValidation: Bool = false
    @Published var isSuspendValidation: Bool = false
    
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
    
    var submitTransactionDetailsSection: (title: String, subtitle: String?) {
        if isStopValidation {
             return ("validation.stop.title".localized, nil)
        } else if isResumeValidation {
            return ("resume.validation".localized, "effective.from".localized)
        } else if isSuspendValidation {
            return ("baking.receiptconfirmation.title.suspend".localized, "effective.from".localized)
        }
        return ("", nil)
    }
    
    init(dataHandler: BakerDataHandler,
         dependencyProvider: ServicesProvider) {
        self.transactionService = dependencyProvider.transactionsService()
        self.storageManager = dependencyProvider.storageManager()
        self.passwordDelegate = DummyRequestPasswordDelegate()
        super.init(dataHandler: dataHandler, account: dataHandler.account)
        self.amountDisplay = dataHandler.getCurrentAmount()?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
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
            sliderButtonText = "submit".localized
        case .updatePool:
            successTransactionText = "validator.update.pool.success".localized
            failedTransactionText = "validator.update.pool.failed".localized
            inProgressTransactionText = "validator.update.pool.in.progress".localized
            sliderButtonText = "submit".localized
        case .updateKeys:
            successTransactionText = "validator.update.keys.success".localized
            failedTransactionText = "validator.update.keys.failed".localized
            inProgressTransactionText = "validator.update.keys.in.progress".localized
            sliderButtonText = "submit".localized
        case .remove:
            successTransactionText = "validator.stop.success".localized
            failedTransactionText = "validator.stop.failed".localized
            inProgressTransactionText = "validator.stop.in.progress".localized
            isStopValidation = true
            sliderButtonText = "baking.menu.stopbaking".localized
        case .register:
            successTransactionText = "validator.registered.success".localized
            failedTransactionText = "validator.registered.failed".localized
            inProgressTransactionText = "validator.registered.in.progress".localized
            shouldDisplayAmount = true
            sliderButtonText = "submit".localized
        case .suspend:
            successTransactionText = "validator.suspend.success".localized
            failedTransactionText = "validator.suspend.failed".localized
            inProgressTransactionText = "validator.suspend.in.progress".localized
            isSuspendValidation = true
            sliderButtonText = "baking.receiptconfirmation.title.suspend".localized
        case .resume:
            successTransactionText = "validator.resume.success".localized
            failedTransactionText = "validator.resume.failed".localized
            inProgressTransactionText = "validator.resume.in.progress".localized
            isResumeValidation = true
            sliderButtonText = "resume.validation".localized
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
                self?.transactionFeeText = cost.displayValue()
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

private extension Optional where Wrapped == ChainParametersEntity {
    var formattedPoolOwnerCooldown: String {
        let cooldown = GeneralFormatter.secondsToDays(seconds: self?.poolOwnerCooldown ?? 0)
        return String(format: "validation.stop.message".localized, cooldown)
    }
}
