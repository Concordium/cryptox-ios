//
//  DelegationAmountInputViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 11.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BigInt

protocol DelegationPoolSelectionDelegate: AnyObject {
    func finishedPoolSelection(dataHandler: StakeDataHandler, bakerPoolResponse: BakerPoolResponse?)
    func switchToRemoveDelegator(cost: GTU, energy: Int)
}

final class DelegationAmountInputViewModel: StakeAmountInputViewModel {
    
    @Published var error: Error?
    @Published var alertOptions: SwiftUIAlertOptions?
    @Published var showAlert: Bool = false
    @Published private var cost: GTU?
    @Published private var energy: Int?
    @Published var restake: Bool = false
    @Published var stakingModeViewModel: DelegationStakingModeViewModel?
    @Published var stakingMode: DelegationStakingMode?
    
    var dataHandler: DelegationDataHandler
    private var validator: StakeAmountInputValidator
    private var transactionService: TransactionsServiceProtocol
    private var stakeService: StakeServiceProtocol
    private var storageManager: StorageManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var navigationManager: NavigationManager
    private var isInCooldown: Bool = false
    init(
        account: AccountDataType,
        dataHandler: DelegationDataHandler,
        navigationManager: NavigationManager
    ) {
        self.dataHandler = dataHandler
        let dependencyProvider = ServicesProvider.defaultProvider()
        self.transactionService = dependencyProvider.transactionsService()
        self.stakeService = dependencyProvider.stakeService()
        self.navigationManager = navigationManager
        self.storageManager = dependencyProvider.storageManager()
        
        let previouslyStakedInPool = GTU(intValue: account.baker?.stakedAmount ?? 0)
        
        validator = StakeAmountInputValidator(
            minimumValue: GTU(intValue: 0),
            balance: GTU(intValue: account.forecastBalance),
            atDisposal: GTU(intValue: account.forecastAtDisposalBalance),
            releaseSchedule: GTU(intValue: account.releaseSchedule?.total ?? 0),
            previouslyStakedInPool: previouslyStakedInPool,
            isInCooldown: account.delegation?.isInCooldown ?? false
        )
        super.init(account: account)
        self.isInCooldown = account.delegation?.isInCooldown ?? false
        let amountData: DelegationAmountData? = dataHandler.getCurrentEntry()
        let restakeData: RestakeDelegationData? = dataHandler.getCurrentEntry()
        self.restake = restakeData?.restake ?? true
        setupPoolLimits(with: nil)
        setup(account: account,
                        currentAmount: amountData?.amount,
                        currentRestakeValue: self.restake,
                        isInCooldown: isInCooldown,
                        validator: validator,
                        showsPoolLimits: showsPoolLimits)
        loadData()
        Publishers.CombineLatest3($amountDecimal, $stakingMode, $amountErrorMessage)
            .map { amount, stakingMode, error in
                let isAmountValid = amount != .zero
                let isStakingModeValid = stakingMode != nil
                let isErrorValid = error == nil
                return isAmountValid && isStakingModeValid && isErrorValid
            }
            .assign(to: &$isContinueEnabled)
    }
    
    func setupPoolLimits(with bakerPoolResponse: BakerPoolResponse?) {
        let newPool: PoolDelegationData? = dataHandler.getNewEntry()
        let existingPool: PoolDelegationData? = dataHandler.getCurrentEntry()
        let previouslyStakedInPool = GTU(intValue: self.account.delegation?.stakedAmount ?? 0)
        // If we are updating delegation and we dont't change the pool,
        // we need to check the existing value of the pool
        let pool: BakerTarget
        if let newPool = newPool?.pool {
            pool = newPool
        } else if let existingPool = existingPool?.pool {
            pool = existingPool
            switch existingPool {
            case .bakerPool(_):
                stakingMode = .validatorPool
            case .passive:
                stakingMode = .passive
            }
        } else {
            pool = .passive
        }
        
        if case .passive = pool {
            showsPoolLimits = false
        } else {
            showsPoolLimits = true
        }
        
        let currentPool: GTU?
        let poolLimit: GTU?
        if let poolResponse = bakerPoolResponse {
            currentPool = GTU(intValue: Int(poolResponse.delegatedCapital))
            poolLimit = GTU(intValue: Int(poolResponse.delegatedCapitalCap))
            self.poolLimit?.value = poolLimit?.displayValueWithCCDStroke() ?? "0.00"
            self.currentPoolLimit?.value = currentPool?.displayValueWithCCDStroke() ?? "0.00"
        } else {
            currentPool = nil
            poolLimit = nil
        }
        
        let minValue: GTU
        if dataHandler.hasCurrentData() {
            minValue = GTU(intValue: 0)
        } else {
            minValue = GTU(intValue: 1)
        }
        
        validator = StakeAmountInputValidator(
            minimumValue: minValue,
            maximumValue: nil,
            balance: GTU(intValue: account.forecastBalance),
            atDisposal: GTU(intValue: account.forecastAtDisposalBalance),
            releaseSchedule: GTU(intValue: account.releaseSchedule?.total ?? 0),
            currentPool: currentPool,
            poolLimit: poolLimit,
            previouslyStakedInPool: previouslyStakedInPool,
            isInCooldown: isInCooldown,
            oldPool: existingPool?.pool,
            newPool: newPool?.pool ?? existingPool?.pool
        )
    }
    
    private lazy var transferCostResult: AnyPublisher<Result<TransferCost, Error>, Never> = {
        let currentAmount = dataHandler.getCurrentEntry(DelegationAmountData.self)?.amount
        let isOnCooldown = account.delegation?.pendingChange?.change != .NoChange
        
        return $isRestakeSelected
            .combineLatest(gtuAmount(currentAmount: currentAmount, isOnCooldown: isOnCooldown))
            .compactMap { [weak self] (restake, amount) -> [TransferCostParameter]? in
                guard let self = self else {
                    return nil
                }
                
                self.dataHandler.add(entry: DelegationAmountData(amount: amount))
                self.dataHandler.add(entry: RestakeDelegationData(restake: restake))
                
                return self.dataHandler.getCostParameters()
            }
            .removeDuplicates()
            .flatMap { [weak self] costParameters -> AnyPublisher<Result<TransferCost, Error>, Never> in
                guard let self = self else {
                    return .just(.failure(StakeError.internalError))
                }
                                
                return self.transactionService
                    .getTransferCost(
                        transferType: self.dataHandler.transferType.toWalletProxyTransferType(),
                        costParameters: costParameters
                    )
                    .asResult()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }()
    
    private func loadData() {
        transferCostResult
            .onlySuccess()
            .sink { [weak self] transferCost in
                guard let self = self else { return }
                
                let cost = transferCost.gtuCost
                self.cost = cost
                self.energy = transferCost.energy
                self.transactionFee = cost.displayValue()
                self.transferCost = ValidatorTransferCostOption.cost(transferCost)
            }
            .store(in: &cancellables)
        
        stakeService.getChainParameters()
            .showLoadingIndicator(in: nil)
            .sink { [weak self] error in
                self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: ErrorMapper.toViewError(error: error).errorDescription ?? error.localizedDescription)
                withAnimation {
                    self?.showAlert = true
                }
            } receiveValue: { [weak self] chainParametersResponse in
                let params = ChainParametersEntity(delegatorCooldown: chainParametersResponse.delegatorCooldown,
                                                   poolOwnerCooldown: chainParametersResponse.poolOwnerCooldown)
                do {
                    _ = try self?.storageManager.updateChainParms(params)
                } catch let error {
                    self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: ErrorMapper.toViewError(error: error).errorDescription ?? error.localizedDescription)
                    withAnimation {
                        self?.showAlert = true
                    }
                }
            }.store(in: &cancellables)
        
        validateAmount()
    }
    
    private func validateAmount() {
        gtuAmount(
            currentAmount: dataHandler.getCurrentEntry(DelegationAmountData.self)?.amount,
            isOnCooldown: isInCooldown
        ).combineLatest(transferCostResult)
            .map { [weak self] (amount, transferCostResult) -> Result<GTU, StakeError> in
                guard let self = self else {
                    return .failure(.internalError)
                }
                
                return transferCostResult
                    .mapError { _ in .internalError }
                    .flatMap { costRange in
                        self.validator.validate(amount: amount, fee: costRange.gtuCost)
                    }
            }
            .sink { [weak self] result in
                switch result {
                case .success:
                    self?.amountErrorMessage = nil
                    self?.poolLimit?.highlighted = false
                case let .failure(error):
                    self?.handleTransferCostError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    override func sendAll() {
        super.sendAll()
        validateAmount()
    }
    
    private func handleTransferCostError(_ error: StakeError) {
        self.amountErrorMessage = error.localizedDescription
        if case .poolLimitReached = error {
            self.poolLimit?.highlighted = true
        } else {
            self.poolLimit?.highlighted = false
        }
        self.isContinueEnabled = false
    }
    
    func pressedContinue() {
        checkForWarnings { [weak self] in
            guard let self = self else { return }
            guard let cost = self.cost else {
                return
            }
            guard let energy = self.energy else {
                return
            }
            if self.dataHandler.isNewAmountZero() {
                self.transactionService.getTransferCost(transferType: WalletProxyTransferType.removeDelegation, costParameters: [])
                    .sink { [weak self] error in
                        self?.alertOptions = AlertHelper.genericErrorAlertOptions(message: ErrorMapper.toViewError(error: error).errorDescription ?? error.localizedDescription)
                        withAnimation {
                            self?.showAlert = true
                        }
                    } receiveValue: {[weak self] transferCost in
                        guard let self else { return }
                        let cost = GTU(intValue: Int(transferCost.cost) ?? 0)
                        removeDelegation { cost, energy in
                            withAnimation {
                                self.showAlert = true
                            }
                            self.alertOptions = AlertHelper.stopDelegationAlertOptions(account: self.account,
                                                                                       cost: cost,
                                                                                       energy: energy,
                                                                                       navigationManager: self.navigationManager)
                        }
                    }.store(in: &self.cancellables)
            } else {
                let viewModel = DelegationSubmissionViewModel(account: account,
                                                              cost: cost,
                                                              energy: energy,
                                                              dataHandler: dataHandler)
                self.navigationManager.navigate(to: .delegationRequestConfirmation(viewModel))
            }
            
        }
    }
    
    private func removeDelegation(completion: @escaping ((GTU, Int) -> Void)) {
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
    
    func checkForWarnings(completion: @escaping () -> Void) {
        if let alert = self.dataHandler.getCurrentWarning(atDisposal: account.forecastAtDisposalBalance + (account.releaseSchedule?.total ?? 0))?.asAlert(completion: completion) {
            isContinueEnabled = false
            alertOptions = alert
            withAnimation {
                showAlert = true
            }
        } else {
            completion()
        }
    }
    
    func stakingModeSelected() {
        stakingModeViewModel = DelegationStakingModeViewModel(account: account, dataHandler: dataHandler)
        stakingModeViewModel?.delegate = self
        if let stakingModeViewModel {
            navigationManager.navigate(to: .delegationStakingMode(stakingModeViewModel))
        }
    }
}

private extension StakeAmountInputViewModel {
    func setup (
        account: AccountDataType,
        currentAmount: GTU?,
        currentRestakeValue: Bool?,
        isInCooldown: Bool,
        validator: StakeAmountInputValidator,
        showsPoolLimits: Bool
    ) {
        let staked = GTU(intValue: account.delegation?.stakedAmount ?? 0)
        amount = Decimal(string: staked.displayValue()) ?? 0
        amountDecimal = BigDecimal(BigInt(account.delegation?.stakedAmount ?? 0), 6)
        self.currentPoolLimit = BalanceViewModel(
            label: "delegation.inputamount.currentpool".localized,
            value: validator.currentPool?.displayValue() ?? GTU(intValue: 0).displayValue(),
            highlighted: false
        )
        self.poolLimit = BalanceViewModel(
            label: "delegation.inputamount.poollimit".localized,
            value: validator.poolLimit?.displayValue() ?? GTU(intValue: 0).displayValue(),
            highlighted: false
        )
        
        self.bottomMessage = "delegation.inputamount.bottommessage".localized
        
        self.isAmountLocked = isInCooldown
        
        self.isRestakeSelected = currentRestakeValue ?? true
        self.showsPoolLimits = showsPoolLimits
        // having a current amount means we are editing
        if let currentAmount = currentAmount {
            if !isInCooldown {
                // we don't set the value if it is in cooldown
                self.amountString = currentAmount.displayValue()
                self.amountMessage = "delegation.inputamount.optionalamount".localized
                self.isContinueEnabled = true
            } else {
                self.amountMessage = "delegation.inputamount.lockedamountmessage".localized
                
                if let poolLimit = validator.poolLimit, let currentPool = validator.currentPool,
                   currentAmount.intValue + currentPool.intValue > poolLimit.intValue {
                    self.poolLimit?.highlighted = true
                    self.amountErrorMessage = "stake.inputAmount.error.amountTooLarge".localized
                    self.isContinueEnabled = false
                } else {
                    self.isContinueEnabled = true
                }
            }
            self.title = "delegation.inputamount.title.update".localized
            
        } else {
            self.title = "delegation.inputamount.title.create".localized
            self.amountMessage = "delegation.inputamount.createamount".localized
        }
    }
}

private extension StakeWarning {
    func asAlert(completion: @escaping () -> Void) -> SwiftUIAlertOptions? {
        switch self {
        case .noChanges:
            let okAction = SwiftUIAlertAction(name: "delegation.nochanges.ok".localized,
                                              completion: nil,
                                              style: .styled
            )
            return SwiftUIAlertOptions(title: "delegation.nochanges.title".localized,
                                       message: "delegation.nochanges.message".localized,
                                       actions: [okAction]
            )
            
        case .amountZero:
            let continueAction = SwiftUIAlertAction(name: "delegation.amountzero.continue".localized,
                                                    completion: completion,
                                                    style: .plain)
            let cancelAction = SwiftUIAlertAction(name: "delegation.amountzero.newstake".localized,
                                                  completion: nil,
                                                  style: .styled)
            return SwiftUIAlertOptions(title: "delegation.amountzero.title".localized,
                                                   message: "delegation.amountzero.message".localized,
                                                   actions: [cancelAction, continueAction])
        case .loweringStake:
            let changeAction = SwiftUIAlertAction(name: "delegation.loweringamountwarning.change".localized,
                                                  completion: nil,
                                                  style: .plain)
            let fineAction = SwiftUIAlertAction(name: "delegation.loweringamountwarning.fine".localized,
                                                completion: completion,
                                                style: .styled)
            return SwiftUIAlertOptions(title: "delegation.loweringamountwarning.title".localized,
                                                   message: "delegation.loweringamountwarning.message".localized,
                                                   actions: [changeAction, fineAction])
        case .moreThan95:
            let continueAction = SwiftUIAlertAction(name: "delegation.morethan95.continue".localized,
                                                    completion: completion,
                                                    style: .styled)
            let newStakeAction = SwiftUIAlertAction(name: "delegation.morethan95.newstake".localized,
                                                    completion: nil,
                                                    style: .plain)
            return SwiftUIAlertOptions(title: "delegation.morethan95.title".localized,
                                       message: "delegation.morethan95.message".localized,
                                       actions: [continueAction, newStakeAction])
        }
    }
}

private extension TransferCost {
    var gtuCost: GTU {
        GTU(intValue: Int(cost) ?? 0)
    }
}

extension DelegationAmountInputViewModel: DelegationPoolSelectionDelegate {
    func switchToRemoveDelegator(cost: GTU, energy: Int) {
        navigationManager.pop()
        withAnimation {
            self.showAlert = true
        }
        self.alertOptions = AlertHelper.stopDelegationAlertOptions(account: self.account,
                                                                   cost: cost,
                                                                   energy: energy,
                                                                   navigationManager: self.navigationManager)
    }
    
    func finishedPoolSelection(dataHandler: StakeDataHandler, bakerPoolResponse: BakerPoolResponse?) {
        setupPoolLimits(with: bakerPoolResponse)
        stakingMode = stakingModeViewModel?.selectedPool
        stakingModeViewModel = nil
        navigationManager.pop()
    }
}
