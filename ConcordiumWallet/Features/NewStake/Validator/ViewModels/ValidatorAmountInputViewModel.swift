//
//  ValidatorAmountInputViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 17.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Combine
import Foundation
import BigInt
import SwiftUI

enum ValidatorTransferCostOption {
    case cost(TransferCost)
    case range(TransferCostRange)
    
    var formattedTransactionFee: String {
        switch self {
            case .cost(let transferCost):
                let gtuCost = GTU(intValue: Int(transferCost.cost) ?? 0)
            return "≈ " + gtuCost.displayValueWithTwoNumbersAfterDecimalPoint()
            case .range(let transferCostRange):
                return transferCostRange.formattedTransactionFee
        }
    }
    
    var cost: TransferCost? {
        switch self {
        case .cost(let transferCost):
            return transferCost
        case .range:
            return nil
        }
    }
    
    var maxCost: GTU {
        switch self {
            case .cost(let transferCost):
                return GTU(intValue: Int(transferCost.cost) ?? 0)
            case .range(let transferCostRange):
                return transferCostRange.maxCost
        }
    }
}

final class ValidatorAmountInputViewModel: StakeAmountInputViewModel {
    
    var dataHandler: BakerDataHandler
    private var validator: StakeAmountInputValidator
    private var transactionService: TransactionsServiceProtocol
    private var stakeService: StakeServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var navigationManager: NavigationManager
    @Published var error: Error?
    @Published var alertOptions: SwiftUIAlertOptions?
    @Published var showAlert: Bool = false
    
    init(
        account: AccountDataType,
        dependencyProvider: StakeCoordinatorDependencyProvider,
        dataHandler: BakerDataHandler,
        navigationManager: NavigationManager
    ) {
        self.dataHandler = dataHandler
        self.transactionService = dependencyProvider.transactionsService()
        self.stakeService = dependencyProvider.stakeService()
        self.navigationManager = navigationManager
        
        let previouslyStakedInPool = GTU(intValue: account.baker?.stakedAmount ?? 0)
        
        validator = StakeAmountInputValidator(
            minimumValue: GTU(intValue: 0),
            balance: GTU(intValue: account.forecastBalance),
            atDisposal: GTU(intValue: account.forecastAtDisposalBalance),
            releaseSchedule: GTU(intValue: account.releaseSchedule?.total ?? 0),
            previouslyStakedInPool: previouslyStakedInPool,
            isInCooldown: account.baker?.isInCooldown ?? false
        )
        super.init(account: account)
        setup(
            account: account,
            currentAmount: dataHandler.getCurrentEntry(BakerAmountData.self)?.amount,
            currentRestakeValue: dataHandler.getCurrentEntry(RestakeBakerData.self)?.restake,
            isInCooldown: account.baker?.isInCooldown ?? false
        )
        loadData()
        
        costRangeResult
            .onlySuccess()
            .map { $0.formattedTransactionFee }
            .assignNoRetain(to: \.transactionFee, on: self)
            .store(in: &cancellables)
    }
    
    private lazy var costRangeResult: AnyPublisher<Result<ValidatorTransferCostOption, Error>, Never> = {
        let currentAmount = dataHandler.getCurrentEntry(BakerAmountData.self)?.amount
        let isOnCooldown = account.baker?.isInCooldown ?? false
        let fetchRange = dataHandler.transferType == .registerBaker
        
        return $isRestakeSelected
            .combineLatest(gtuAmount(currentAmount: currentAmount, isOnCooldown: isOnCooldown))
            .compactMap { [weak self] (restake, amount) -> [TransferCostParameter]? in
                guard let self = self else {
                    return nil
                }
                
                self.dataHandler.add(entry: BakerAmountData(amount: amount))
                self.dataHandler.add(entry: RestakeBakerData(restake: restake))
                
                return self.dataHandler.getCostParameters()
            }
            .removeDuplicates()
            .flatMap { [weak self] (costParameters) -> AnyPublisher<Result<ValidatorTransferCostOption, Error>, Never> in
                guard let self = self else {
                    return .just(.failure(StakeError.internalError))
                }
                
                self.isContinueEnabled = false
                if fetchRange {
                    return self.transactionService
                        .getBakingTransferCostRange(parameters: costParameters)
                        .map { ValidatorTransferCostOption.range($0) }
                        .asResult()
                        .eraseToAnyPublisher()
                } else {
                    return self.transactionService
                        .getTransferCost(transferType: self.dataHandler.transferType.toWalletProxyTransferType(), costParameters: costParameters)
                        .map { ValidatorTransferCostOption.cost($0) }
                        .asResult()
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }()
    
    func loadData() {
        loadPoolParameters()
        
        costRangeResult
            .onlySuccess()
            .map { $0.formattedTransactionFee }
            .assignNoRetain(to: \.transactionFee, on: self)
            .store(in: &cancellables)
        
        costRangeResult
            .onlySuccess()
            .map { $0 }
            .assignNoRetain(to: \.transferCost, on: self)
            .store(in: &cancellables)
        
        gtuAmount(
            currentAmount: dataHandler.getCurrentEntry(BakerAmountData.self)?.amount,
            isOnCooldown: account.baker?.isInCooldown ?? false
        )
        .combineLatest(costRangeResult)
        .map { [weak self] (amount, rangeResult) -> Result<GTU, StakeError> in
            guard let self = self else {
                return .failure(StakeError.internalError)
            }
            
            // in case when validators want to change their restaking preference
            // we allow to modify validator options in case when amount not changed
            if let baker = account.baker, baker.stakedAmount == amount.intValue {
                return .success(amount)
            }
            
            return rangeResult
                .mapError { _ in StakeError.internalError }
                .flatMap { costRange in
                    self.validator.validate(amount: amount, fee: costRange.maxCost)
                }
        }
        .sink { [weak self] result in
            switch result {
                case let .failure(error):
                    self?.isContinueEnabled = false
                    self?.amountErrorMessage = error.localizedDescription
                case .success(_):
                    self?.isContinueEnabled = true
                    self?.amountErrorMessage = nil
            }
        }
        .store(in: &cancellables)
    }
    
    private struct RemoteParameters {
        let minimumValue: GTU
        let maximumValue: GTU
        let comissionData: BakerCommissionData
    }
    
    ///
    /// `ValidatorPoolData` contained needed data to show on tx approve UI current  pool commisions state
    /// - `rates`commisiotn rate for validator pool, to update commision data
    /// - `delegatedCapital` - is for baker pool delegated capital
    ///
    typealias ValidatorPoolData = (rates: CommissionRates?, delegatedCapital: Int)
    
    private func loadPoolParameters() {
        let passiveDelegationRequest = stakeService.getPassiveDelegation()
        let chainParametersRequest = stakeService.getChainParameters()
        let validatorData = Just(account.baker?.bakerID)
            .setFailureType(to: Error.self)
            .flatMap { [weak self] bakerId -> AnyPublisher<ValidatorPoolData, Error> in
                guard let self = self, let bakerId = bakerId else {
                    return .just((nil, 0))
                }
                
                return self.stakeService.getBakerPool(bakerId: bakerId)
                    .map { bakerPool in
                        (bakerPool.poolInfo.commissionRates,  Int(bakerPool.delegatedCapital) ?? 0)
                    }
                    .eraseToAnyPublisher()
            }
        
        passiveDelegationRequest
            .zip(chainParametersRequest, validatorData)
            .asResult()
            .sink { [weak self] (result) in
                self?.handleParametersResult(result.map { (passiveDelegation, chainParameters, validatorData) in
                    let (commissionRates, delegatedCapital) = validatorData
                    let totalCapital = Int(passiveDelegation.allPoolTotalCapital) ?? 0
                    // We make sure to first convert capitalBound to an Int so we don't have to do floating point arithmetic
                    let availableCapital = (totalCapital * Int(chainParameters.capitalBound * 100) / 100) - delegatedCapital
                    
                    return RemoteParameters(
                        minimumValue: GTU(intValue: Int(chainParameters.minimumEquityCapital) ?? 0),
                        maximumValue: GTU(intValue: availableCapital),
                        comissionData: BakerCommissionData(
                            // In case when account is a `baker/validator`, we use baker commission data for this pool.
                            // Else, we take chain parameters as `commissionData`.
                            bakingRewardComission: commissionRates?.bakingCommission ?? chainParameters.bakingCommissionRange.max,
                            finalizationRewardComission: commissionRates?.finalizationCommission ?? chainParameters.finalizationCommissionRange.max,
                            transactionComission: commissionRates?.transactionCommission ?? chainParameters.transactionCommissionRange.max
                        )
                    )
                })
            }
            .store(in: &cancellables)
    }
    
    private func handleParametersResult(_ result: Result<RemoteParameters, Error>) {
        switch result {
            case let .failure(error):
            isContinueEnabled = false
            self.error = error
        case let .success(parameters):
                self.validator.minimumValue = parameters.minimumValue
                self.validator.maximumValue = parameters.maximumValue
                self.dataHandler.add(entry: parameters.comissionData)
        }
    }
    
    func pressedContinue() {
        checkForWarnings { [weak self] in
            guard let self = self else { return }
            if self.dataHandler.isNewAmountZero() {
                withAnimation {
                    self.showAlert = true
                }
                alertOptions = AlertHelper.stopValidationAlertOptions(account: account, navigationManager: navigationManager)
            } else {
                finishedEnteringAmount()
            }
        }
    }
    
    private func finishedEnteringAmount() {
        if case .updateBakerStake = dataHandler.transferType {
            let viewModel = ValidatorSubmissionViewModel(dataHandler: dataHandler,
                                                         dependencyProvider: ServicesProvider.defaultProvider())
            navigationManager.navigate(to: .validatorRequestConfirmation(viewModel))
        } else {
            navigationManager.navigate(to: .openningPool(ValidatorPoolSettingsViewModel(
                dataHandler: dataHandler,
                navigationManager: navigationManager
            )))
        }
    }
    
    private func checkForWarnings(completion: @escaping () -> Void) {
        if let alert = dataHandler.getCurrentWarning(
            atDisposal: account.forecastAtDisposalBalance + (account.releaseSchedule?.total ?? 0)
        )?.asAlert(completion: completion) {
            isContinueEnabled = false
            alertOptions = alert
            withAnimation {
                showAlert = true
            }
        } else {
            completion()
        }
    }
}

private extension StakeAmountInputViewModel {
    func setup(
        account: AccountDataType,
        currentAmount: GTU?,
        currentRestakeValue: Bool?,
        isInCooldown: Bool
    ) {
        let staked = GTU(intValue: account.baker?.stakedAmount ?? 0)
        amount = Decimal(string: staked.displayValue()) ?? 0
        amountDecimal = BigDecimal(BigInt(account.baker?.stakedAmount ?? 0), 6)
        self.showsPoolLimits = false
        self.isAmountLocked = isInCooldown
        self.bottomMessage = "baking.inputamount.bottommessage".localized
        self.isRestakeSelected = currentRestakeValue ?? true
        
        if let currentAmount = currentAmount {
            if !isInCooldown {
                self.amountString = currentAmount.displayValue()
                self.amountMessage = "baking.inputamount.newamount".localized
            } else {
                self.amountMessage = "baking.inputamount.lockedamountmessage".localized
            }
            
            self.title = "baking.inputamount.title.update".localized
        } else {
            self.title = "baking.inputamount.title.create".localized
            self.amountMessage = "baking.inputamount.createamount".localized
        }
    }
}

private extension StakeWarning {
    func asAlert(completion: @escaping () -> Void) -> SwiftUIAlertOptions? {
        switch self {
            case .noChanges:
            let okAction = SwiftUIAlertAction(
                name: "baking.nochanges.ok".localized,
                completion: nil,
                style: .styled
            )
            return SwiftUIAlertOptions(
                title: "baking.nochanges.title".localized,
                message: "baking.nochanges.message".localized,
                actions: [okAction]
            )
            case .loweringStake:
                return nil
            case .moreThan95:
            let continueAction = SwiftUIAlertAction(name: "baking.morethan95.continue".localized, completion: completion, style: .styled)
                let newStakeAction = SwiftUIAlertAction(name: "baking.morethan95.newstake".localized,
                                                 completion: nil,
                                                        style: .plain)
                return SwiftUIAlertOptions(title: "baking.morethan95.title".localized,
                                    message: "baking.morethan95.message".localized,
                                    actions: [continueAction, newStakeAction])
            case .amountZero:
                return nil
        }
    }
}

private extension BakerDataType {
   var isInCooldown: Bool {
       if let pendingChange = pendingChange, pendingChange.change != .NoChange {
           return true
       } else {
           return false
       }
   }
}

private extension TransferCostRange {
    var formattedTransactionFee: String {
        String(
            format: "baking.inputamount.transactionfee".localized,
            minCost.displayValueWithTwoNumbersAfterDecimalPoint(),
            maxCost.displayValueWithTwoNumbersAfterDecimalPoint()
        )
    }
}
