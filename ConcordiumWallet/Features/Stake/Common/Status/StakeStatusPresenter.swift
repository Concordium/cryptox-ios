//
//  StakeStatusPresenter.swift
//  ConcordiumWallet
//
//  Created by Ruxandra Nistor on 23/03/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: Presenter
protocol StakeStatusPresenterProtocol: AnyObject {
	var view: StakeStatusViewProtocol? { get set }
    func viewDidLoad()
    func pressedButton()
    func pressedStopButton()
    func closeButtonTapped()
    func updateStatus()
}

class StakeStatusViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var topText: String = ""
    @Published var topImageName: String = ""
    @Published var placeholderText: String?
    
    @Published var gracePeriodText: String?
    @Published var bottomInfoMessage: String?
    @Published var bottomImportantMessage: String?
    
    @Published var newAmount: String?
    @Published var newAmountLabel: String?
    
    @Published var stopButtonEnabled: Bool = true
    @Published var stopButtonShown: Bool = true
    @Published var stopButtonLabel: String = ""
    
    @Published var updateButtonEnabled: Bool = true
    @Published var buttonLabel: String = ""
    @Published var accountCooldowns: [CooldownDataType] = []
    
    @Published var rows: [StakeRowViewModel] = []
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var account: AccountDataType
    private var transactionService: TransactionsServiceProtocol
    private var stakeService: StakeServiceProtocol
    private var storageManager: StorageManagerProtocol
    private var accountsService: AccountsServiceProtocol
    weak var delegate: DelegationStatusPresenterDelegate?
    
    init(
        account: AccountDataType,
        dependencyProvider: StakeCoordinatorDependencyProvider,
        delegate: DelegationStatusPresenterDelegate? = nil
    ) {
        self.account = account
        self.transactionService = dependencyProvider.transactionsService()
        self.stakeService = dependencyProvider.stakeService()
        self.storageManager = dependencyProvider.storageManager()
        self.accountsService = dependencyProvider.accountsService()
        self.delegate = delegate
        loadData()
    }
    
    
    func setup(dataHandler: StakeDataHandler) {
        rows = dataHandler
            .getCurrentOrdered()
            .map { StakeRowViewModel(displayValue: $0) }
    }
    
    func loadData() {
        setupWith(
            account: account,
            transfers: storageManager.getDelegationTransfers(for: account)
        )
    }
    
    func pressedButton() {
        stakeService.getChainParameters()
            .sink { [weak self] error in
                self?.error = error
            } receiveValue: { [weak self] chainParametersResponse in
                let params = ChainParametersEntity(delegatorCooldown: chainParametersResponse.delegatorCooldown,
                                                   poolOwnerCooldown: chainParametersResponse.poolOwnerCooldown)
                do {
                    _ = try self?.storageManager.updateChainParms(params)
                    self?.delegate?.pressedRegisterOrUpdate()
                } catch let error {
                    self?.error = error
                }
            }.store(in: &cancellables)
    }
    
    func pressedStopButton() {
        stakeService.getChainParameters()
            .zip(transactionService.getTransferCost(transferType: .removeDelegation, costParameters: []))
            .sink { [weak self] error in
                self?.error = error
            } receiveValue: { [weak self] (chainParametersResponse, transferCost) in
                let params = ChainParametersEntity(delegatorCooldown: chainParametersResponse.delegatorCooldown,
                                                   poolOwnerCooldown: chainParametersResponse.poolOwnerCooldown)
                do {
                    _ = try self?.storageManager.updateChainParms(params)
                    let cost = GTU(intValue: Int(transferCost.cost) ?? 0)
                    self?.delegate?.pressedStop(cost: cost, energy: transferCost.energy)
                } catch let error {
                    self?.error = error
                }
            }.store(in: &cancellables)
    }
    
    func setupWith(account: AccountDataType, transfers: [TransferDataType]) {
        if transfers.count > 0 {
            self.setup(account: account, pendingChanges: .none, hasUnfinishedTransaction: true)
        } else {
            let setupViewModel = { (pendingChange: PendingChanges) in
                self.setup(account: account, pendingChanges: pendingChange, hasUnfinishedTransaction: false)
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
                        print(error.localizedDescription)
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
    
    func closeButtonTapped() {
        self.delegate?.pressedClose()
    }
    
    func updateStatus() {
        storageManager.getDelegationTransfers(for: account)
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transfer -> AnyPublisher<TransferDataType, Error> in
                guard let self = self else {
                    return AnyPublisher.empty()
                }
                
                return accountsService
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

extension StakeStatusViewModel {
    // swiftlint:disable function_body_length
    func setup(
        account: AccountDataType,
        pendingChanges: PendingChanges,
        hasUnfinishedTransaction: Bool
    ) {
        setup(dataHandler: DelegationDataHandler(account: account, isRemoving: false))
        title = "delegation.status.title".localized
        stopButtonLabel = "delegation.status.stopbutton".localized
        topImageName = "confirm"
        if hasUnfinishedTransaction {
            topImageName = "logo_rotating_arrows"
            topText = "delegation.status.waiting.header".localized
            placeholderText = "delegation.status.waiting.placeholder".localized
            buttonLabel = "delegation.status.updatebutton".localized
            updateButtonEnabled = false
            stopButtonEnabled = false
            rows.removeAll()
            return
        }
        
        placeholderText = nil
        topText = "delegation.status.registered.header".localized
        buttonLabel = "delegation.status.updatebutton".localized
        switch pendingChanges {
        case .none:
            gracePeriodText = nil
            bottomInfoMessage = nil
            bottomImportantMessage = nil
            newAmount = nil
            newAmountLabel = nil
            stopButtonEnabled = true
            updateButtonEnabled = true
        case .newDelegationAmount(let cooldownTimestampUTC, let newDelegationAmount):
            gracePeriodText = String(format: "delegation.status.graceperiod".localized,
                                     GeneralFormatter.formatDateWithTime(for: GeneralFormatter.dateFrom(timestampUTC: cooldownTimestampUTC)))
            bottomInfoMessage = nil
            bottomImportantMessage = nil
            newAmountLabel = "delegation.status.newamount".localized
            newAmount = newDelegationAmount.displayValueWithGStroke()
            stopButtonEnabled = false
            updateButtonEnabled = true
        case .stoppedDelegation(let cooldownTimestampUTC):
            gracePeriodText = String(format: "delegation.status.graceperiod".localized,
                                     GeneralFormatter.formatDateWithTime(for: GeneralFormatter.dateFrom(timestampUTC: cooldownTimestampUTC)))
            bottomInfoMessage = "delegation.status.delegationwillstop".localized
            bottomImportantMessage = nil
            newAmount = nil
            newAmountLabel = nil
            stopButtonEnabled = false
            updateButtonEnabled = true
        case .poolWasDeregistered(let cooldownTimestampUTC):
            gracePeriodText = nil
            bottomInfoMessage = nil
            bottomImportantMessage =  String(format: "delegation.status.deregisteredcooldown".localized,
                                             GeneralFormatter.formatDateWithTime(for: GeneralFormatter.dateFrom(timestampUTC: cooldownTimestampUTC)))
            newAmount = nil
            newAmountLabel = nil
            stopButtonEnabled = true
            updateButtonEnabled = true
        }
    }
}

