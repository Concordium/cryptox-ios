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
    @Published var isResumeDelegation: Bool = false
    @Published var isSuspendDelegation: Bool = false
    
    private var cost: GTU
    private var energy: Int
    
    private var transactionsService: TransactionsServiceProtocol
    private var stakeService: StakeServiceProtocol
    private var storeManager: StorageManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let dependencyProvider = ServicesProvider.defaultProvider()
    private let passwordDelegate: RequestPasswordDelegate

    init(account: AccountDataType,
         delegate: (DelegationReceiptConfirmationPresenterDelegate & RequestPasswordDelegate)?,
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
        setup(isUpdate: dataHandler.hasCurrentData(),
                             isLoweringStake: isLoweringStake,
                             gracePeriod: chainParams?.delegatorCooldown ?? 0,
                             transferCost: cost,
                             isRemoving: dataHandler.transferType == .removeDelegation)
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
    
    func closeTapped(completion: @escaping () -> Void) {
        if !isTransactionExecuting && error == nil && isStopDelegation {
            alertOptions = stopDelegationAlertOptions(completion: completion)
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
        } else if isRemoving {
            title = "delegation.receiptconfirmation.title.remove".localized
            text = "delegation.receipt.removedelegation".localized
            receiptHeaderText = "delegation.receipt.removedelegationheader".localized
        } else {
            title = "delegation.receiptconfirmation.title.create".localized
            receiptHeaderText = "delegation.receipt.registerdelegation".localized
            text = String(format: "delegation.receiptconfirmation.registertext".localized, gracePeriod)
        }
        transactionFeeText = String(format: "delegation.receiptconfirmation.transactionfee".localized, transferCost.displayValueWithGStroke())
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
}
