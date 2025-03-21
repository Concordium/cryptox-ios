//
//  DelegationSubmissionViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class DelegationSubmissionViewModel: StakeReceiptViewModel, ObservableObject {
    
    @Published var isStopDelegation: Bool = false
    @Published var isUpdateDelegation: Bool = false
    var stakingMode: DelegationStakingMode?
    var restakeText: String = ""
    private var cost: GTU
    private var energy: Int
    let ticker: String = "CCD"
    private var transactionsService: TransactionsServiceProtocol
    private var stakeService: StakeServiceProtocol
    private var storeManager: StorageManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dependencyProvider = ServicesProvider.defaultProvider()
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
        if isStopDelegation {
            return ("stop.staking".localized, nil)
        }
        return ("", "")
    }
    
    init(account: AccountDataType,
         cost: GTU,
         energy: Int,
         dataHandler: DelegationDataHandler) {
        self.cost = cost
        self.energy = energy
        self.transactionsService = dependencyProvider.transactionsService()
        self.stakeService = dependencyProvider.stakeService()
        self.storeManager = dependencyProvider.storageManager()
        self.passwordDelegate = DummyRequestPasswordDelegate()
        super.init(dataHandler: dataHandler, account: account)
        let isLoweringStake = dataHandler.isLoweringStake()
        let chainParams = self.storeManager.getChainParams()
        self.amountDisplay = dataHandler.getCurrentAmount()?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
        setupVisibleFields()
        setup(isUpdate: isUpdateDelegation,
                             isLoweringStake: isLoweringStake,
                             gracePeriod: chainParams?.delegatorCooldown ?? 0,
                             transferCost: cost,
                             isRemoving: isStopDelegation)
    }

    func pressedButton() {
        let transfer = dataHandler.getTransferObject(cost: cost, energy: energy)
        
        self.transactionsService.performTransfer(transfer, from: account, requestPasswordDelegate: passwordDelegate)
            .tryMap(self.storeManager.storeTransfer)
            .sink(receiveError: { error in
                if case GeneralError.userCancelled = error { return }
                self.error = ErrorMapper.toViewError(error: error)
            }, receiveValue: { [weak self] transfer in
                self?.transferDataType = transfer
                self?.isTransactionExecuting = false
            }).store(in: &cancellables)
    }
    
    private func setupVisibleFields() {
        self.isUpdateDelegation = dataHandler.hasCurrentData()
        self.isStopDelegation = dataHandler.transferType == .removeDelegation
        let restakeData: RestakeDelegationData? = dataHandler.getNewEntry() ?? dataHandler.getCurrentEntry()
        restakeText = restakeData?.displayValue ?? ""
        let currentPoolData: PoolDelegationData? = dataHandler.getNewEntry() ?? dataHandler.getCurrentEntry()
        if let pool = currentPoolData?.pool {
            if case BakerTarget.passive = pool {
                self.stakingMode = .passive
            } else {
                self.stakingMode = .validatorPool
            }
        }
    }
    
    private func stopValidationAlertOptions(completion: @escaping () -> Void) -> SwiftUIAlertOptions {
        let okAction = SwiftUIAlertAction(
            name: "baking.nochanges.ok".localized,
            completion: completion,
            style: .styled
        )
        return SwiftUIAlertOptions(
            title: "delegation.receiptremove.title".localized,
            message: storeManager.getChainParams().formattedDelegatorCooldown,
            actions: [okAction]
        )
    }
    
    func closeTapped(completion: @escaping () -> Void) {
        if !isTransactionExecuting && error == nil && isStopDelegation {
            alertOptions = stopValidationAlertOptions(completion: completion)
            withAnimation {
                showAlert = true
            }
        } else {
            completion()
        }
    }
}

fileprivate extension StakeReceiptViewModel {
    func setup(isUpdate: Bool, isLoweringStake: Bool, gracePeriod: Int, transferCost: GTU, isRemoving: Bool) {
        receiptFooterText = nil
        showsSubmitted = false
        let gracePeriod = String(format: "delegation.graceperiod.format".localized, GeneralFormatter.secondsToDays(seconds: gracePeriod))
        buttonLabel = "delegation.receiptconfirmation.submit".localized
        if isUpdate {
            title = "delegation.receiptconfirmation.title.update".localized
            if isLoweringStake {
                text = String(format: "delegation.receiptconfirmation.loweringstake".localized, gracePeriod)
            } else {
                text = "delegation.receiptconfirmation.updatetext".localized
            }
            receiptHeaderText = "delegation.receipt.updatedelegation".localized
            sliderButtonText = "submit".localized
            inProgressTransactionText = "delegation.update.in.progress".localized
            failedTransactionText = "delegation.update.failed".localized
            successTransactionText = "delegation.update.success".localized
            shouldDisplayAmount = true
        } else if isRemoving {
            title = "delegation.receiptconfirmation.title.remove".localized
            sliderButtonText = "baking.menu.stopbaking".localized
            inProgressTransactionText = "delegation.stop.in.progress".localized
            failedTransactionText = "delegation.stop.failed".localized
            successTransactionText = "delegation.stop.success".localized
        } else {
            title = "delegation.receiptconfirmation.title.create".localized
            sliderButtonText = "delegation.submit.delegation".localized
            inProgressTransactionText = "delegation.registered.in.progress".localized
            failedTransactionText = "delegation.registered.failed".localized
            successTransactionText = "delegation.registered.success".localized
            shouldDisplayAmount = true
        }
        transactionFeeText = transferCost.displayValue()
    }
}

extension DelegationSubmissionViewModel {
    private func stopDelegationAlertOptions(completion: @escaping () -> Void) -> SwiftUIAlertOptions {
        let okAction = SwiftUIAlertAction(
            name: "errorAlert.continueButton".localized,
            completion: completion,
            style: .plain
        )
        let goBackAction = SwiftUIAlertAction(
            name: "go.back".localized,
            completion: nil,
            style: .styled
        )
        return SwiftUIAlertOptions(
            title: "delegation.stop.alert.title".localized,
            message: "delegation.stop.alert.message".localized,
            actions: [goBackAction, okAction]
        )
    }
//    
//    private func alertOptions(completion: @escaping () -> Void) -> SwiftUIAlertOptions {
//        
//    }
}

private extension Optional where Wrapped == ChainParametersEntity {
    var formattedDelegatorCooldown: String {
        let delegatorCooldown = GeneralFormatter.secondsToDays(seconds: self?.delegatorCooldown ?? 0)
        let gracePeriod = String(
            format: "delegation.graceperiod.format".localized,
            GeneralFormatter.secondsToDays(seconds: delegatorCooldown)
        )
        return String(format: "delegation.receiptremove.message".localized, gracePeriod)
    }
}
