//
//  DelegationStatusViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

final class DelegationStatusViewModel: ObservableObject {
    @Published var rows: [StakeRowViewModel] = []
    @Published var error: StakeStatusViewModelError?
    @Published var accountCooldowns: [AccountCooldown] = []
    @Published var stopButtonShown: Bool = true
    @Published var updateButtonEnabled: Bool = true
    @Published var title: String = ""
    @Published var topText: String = ""
    @Published var topImageName: String = ""
    @Published var placeholderText: String?
    @Published var showAlert: Bool = false
    @Published var alertOptions: SwiftUIAlertOptions?
    @Published var isRegistered: Bool = false
    @Published var isSuspended: Bool = false
    @Published var isPrimedForSuspension: Bool = false
    @Published var hasUnfinishedTransactions: Bool = false

    private var dataHandler: StakeDataHandler?
    private let account: AccountDataType
    private let stakeService: StakeServiceProtocol
    private let storageManager: StorageManagerProtocol
    private let accountsService: AccountsServiceProtocol
    private var poolInfo: PoolInfo?
    private var cancellables = Set<AnyCancellable>()
    private let navigationManager: NavigationManager
    private let dependencyProvider = ServicesProvider.defaultProvider()
    
    init(account: AccountDataType,
         dependencyProvider: StakeCoordinatorDependencyProvider,
         navigationManager: NavigationManager) {
        self.account = account
        self.navigationManager = navigationManager
        self.stakeService = dependencyProvider.stakeService()
        self.storageManager = dependencyProvider.storageManager()
        self.accountsService = dependencyProvider.accountsService()
        setupWith(
            account: account,
            transfers: storageManager.getDelegationTransfers(for: account)
        )
    }
    
    func actionItems() -> [ActionItem] {
        var actionItems = [ActionItem]()
        if stopButtonShown {
            actionItems.append(ActionItem(iconName: "Stop", label: "Stop", action: { [weak self] in
                guard let self else { return }
                stopTapped { cost, energy in
                    withAnimation {
                        self.showAlert = true
                    }
                    self.alertOptions = AlertHelper.stopDelegationAlertOptions(account: self.account,
                                                                               cost: cost,
                                                                               energy: energy,
                                                                               navigationManager: self.navigationManager)
                }
            }))
        }
        actionItems.append(ActionItem(iconName: "ArrowsClockwise", label: "Update", action: { [weak self] in
            self?.updateTapped()
        }))
        return actionItems
    }
    
    private func updateTapped() {
        stakeService.getChainParameters()
            .sink { [weak self] error in
                withAnimation {
                    self?.showAlert = true
                }
                self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: StakeStatusViewModelError(error).error.localizedDescription)
            } receiveValue: { [weak self] chainParametersResponse in
                guard let self = self else { return }
                let params = ChainParametersEntity(delegatorCooldown: chainParametersResponse.delegatorCooldown,
                                                   poolOwnerCooldown: chainParametersResponse.poolOwnerCooldown)
                do {
                    _ = try self.storageManager.updateChainParms(params)
                    let viewModel = DelegationAmountInputViewModel(account: account, dataHandler: DelegationDataHandler(account: account, isRemoving: false), navigationManager: navigationManager)
                    navigationManager.navigate(to: .delegationAmountInput(viewModel))
                } catch let error {
                    withAnimation {
                        self.showAlert = true
                    }
                    self.alertOptions = AlertHelper.genericErrorAlertOptions(message: StakeStatusViewModelError(error).error.localizedDescription)
                }
            }.store(in: &cancellables)
    }
    
    private func stopTapped(completion: @escaping ((GTU, Int) -> Void)) {
        let transactionService = dependencyProvider.transactionsService()
        stakeService.getChainParameters()
            .zip(transactionService.getTransferCost(transferType: .removeDelegation, costParameters: []))
            .sink { [weak self] error in
                withAnimation {
                    self?.showAlert = true
                }
                self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: StakeStatusViewModelError(error).error.localizedDescription)
            } receiveValue: {[weak self] (chainParametersResponse, transferCost) in
                let params = ChainParametersEntity(delegatorCooldown: chainParametersResponse.delegatorCooldown,
                                                   poolOwnerCooldown: chainParametersResponse.poolOwnerCooldown)
                do {
                    _ = try self?.storageManager.updateChainParms(params)
                    let cost = GTU(intValue: Int(transferCost.cost) ?? 0)
                    completion(cost, transferCost.energy)
                } catch let error {
                    withAnimation {
                        self?.showAlert = true
                    }
                    self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: StakeStatusViewModelError(error).error.localizedDescription)
                }
            }.store(in: &cancellables)
    }
}

// MARK: - Setup methods
extension DelegationStatusViewModel {
    func setupWith(
        account: AccountDataType,
        transfers: [TransferDataType]
    ) {
        if transfers.count > 0 {
            self.setup(account: account, pendingChanges: .none, hasUnfinishedTransaction: true)
        } else {
            let setupViewModel = { (pendingChange: PendingChanges) in
                self.setup(
                    account: account,
                    pendingChanges: pendingChange,
                    hasUnfinishedTransaction: false
                )
            }
            
            let accountPendingChange = account.delegation?.pendingChange
            switch accountPendingChange?.change {
            case .ReduceStake:
                setupViewModel(.newDelegationAmount(
                    coolDownEndTimestamp: accountPendingChange?.estimatedChangeTime ?? "",
                    newDelegationAmount: GTU(intValue: Int(accountPendingChange?.updatedNewStake ?? "0") ?? 0))
                )
            case .RemoveStake:
                setupViewModel(.stoppedDelegation(coolDownEndTimestamp: accountPendingChange?.estimatedChangeTime ?? ""))
            case .NoChange, nil:
                if let bakerId = account.delegation?.delegationTargetBakerID, bakerId != -1 {
                    self.stakeService.getBakerPool(bakerId: bakerId).sink { error in
                        withAnimation {
                            self.showAlert = true
                        }
                        self.alertOptions = AlertHelper.genericErrorAlertOptions(message: StakeStatusViewModelError(error).error.localizedDescription)
                    } receiveValue: { bakerPoolResponse in
                        if bakerPoolResponse.bakerStakePendingChange.pendingChangeType == "RemovePool" {
                            let effectiveTime = bakerPoolResponse.bakerStakePendingChange.estimatedChangeTime ?? ""
                            setupViewModel(.poolWasDeregistered(coolDownEndTimestamp: effectiveTime))
                        } else {
                            setupViewModel(.none)
                        }
                    }.store(in: &cancellables)
                } else {
                    setupViewModel(.none)
                }
            }
        }
    }
    
    func setup(
        account: AccountDataType,
        pendingChanges: PendingChanges,
        hasUnfinishedTransaction: Bool
    ) {
        setup(dataHandler: DelegationDataHandler(account: account, isRemoving: false))
        isSuspended = account.delegation?.isSuspended ?? false
        isPrimedForSuspension = account.delegation?.isPrimedForSuspension ?? false
        title = "delegation.status.title".localized
        topImageName = "confirm"
        hasUnfinishedTransactions = hasUnfinishedTransaction
        if hasUnfinishedTransaction {
            topImageName = "ArrowsClockwise"
            topText = "delegation.status.waiting.header".localized
            placeholderText = "delegation.status.waiting.placeholder".localized
            updateButtonEnabled = false
            stopButtonShown = false
            rows.removeAll()
            return
        }
        
        placeholderText = nil
        topText = "delegation.status.registered.header".localized
        accountCooldowns = account.cooldowns.map({AccountCooldown(timestamp: $0.timestamp, amount: $0.amount, status: $0.status.rawValue)})
        switch pendingChanges {
        case .none, .poolWasDeregistered(_):
            stopButtonShown = true
            updateButtonEnabled = true
        case .newDelegationAmount(_,_), .stoppedDelegation(_):
            stopButtonShown = false
            updateButtonEnabled = true
        }
        accountCooldowns = account.cooldowns.map({AccountCooldown(timestamp: $0.timestamp, amount: $0.amount, status: $0.status.rawValue)})
    }
    
    func setup(dataHandler: StakeDataHandler) {
        rows = dataHandler
            .getCurrentOrdered()
            .map { StakeRowViewModel(displayValue: $0) }
    }
}

// MARK: - Status handling
extension DelegationStatusViewModel {
    
    func updateStatus() {
        storageManager.getDelegationTransfers(for: account)
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transfer -> AnyPublisher<TransferDataType, Error> in
                guard let self = self else {
                    return AnyPublisher.empty()
                }
                
                return self.accountsService
                    .getLocalTransferWithUpdatedStatus(transfer: transfer, for: self.account)
                    .eraseToAnyPublisher()
            }
            .collect()
            .zip(accountsService.recalculateAccountBalance(account: account, balanceType: .total))
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (transfers, account) in
                    if let self = self {
                        self.setupWith(
                            account: account,
                            transfers: transfers
                        )
                    }
                }
            )
            .store(in: &cancellables)
        
    }
}

extension DelegationStatusViewModel: Equatable, Hashable {
    static func == (lhs: DelegationStatusViewModel, rhs: DelegationStatusViewModel) -> Bool {
        lhs.rows == rhs.rows &&
        lhs.stopButtonShown == rhs.stopButtonShown &&
        lhs.updateButtonEnabled == rhs.updateButtonEnabled &&
        lhs.account.address == rhs.account.address &&
        lhs.accountCooldowns.map(\.id) == rhs.accountCooldowns.map(\.id)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rows)
        hasher.combine(stopButtonShown)
        hasher.combine(updateButtonEnabled)
        hasher.combine(account.address)
        hasher.combine(accountCooldowns.map(\.id))
    }
}
