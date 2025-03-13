//
//  DelegationStakingModeViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 11.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

enum DelegationStakingMode: String {
    case passive = "Passive delegation"
    case validatorPool = "Targeted delegation"
}

class DelegationStakingModeViewModel: ObservableObject {
    @Published var selectedPool: DelegationStakingMode = .passive
    @Published var validatorId: String = ""
    @Published var validatorIdErrorMessage: String? = nil
    @Published var bottomMessage: String = ""
    @Published var bakerPoolResponse: BakerPoolResponse? = nil
    @Published private var validSelectedPool: BakerTarget? = .passive
    @Published var isContinueEnabled: Bool = false
    @Published var alertOptions: SwiftUIAlertOptions?
    @Published var showAlert: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let stakeService: StakeServiceProtocol
    private let transactionService: TransactionsServiceProtocol
    private let dataHandler: StakeDataHandler
    private let account: AccountDataType
    private let dependencyProvider = ServicesProvider.defaultProvider()
    weak var delegate: DelegationPoolSelectionDelegate?
    
    init(account: AccountDataType,
         dataHandler: StakeDataHandler) {
        self.account = account
        self.stakeService = dependencyProvider.stakeService()
        self.transactionService = dependencyProvider.transactionsService()
        self.dataHandler = dataHandler
        let currentPoolData: PoolDelegationData? = dataHandler.getNewEntry() ?? dataHandler.getCurrentEntry()
        if let pool = currentPoolData?.pool {
            self.validSelectedPool = pool
            if case BakerTarget.passive = pool {
                self.selectedPool = .passive
            } else {
                self.selectedPool = .validatorPool
                self.validatorId = pool.getDisplayValue()
            }
        }
        setupBindings()
    }

    private func setupBindings() {
        $validatorId
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { [weak self] bakerId -> AnyPublisher<Result<Int, DelegationPoolBakerIdError>, Never> in
                guard let self = self, selectedPool != .passive else { return .just(.failure(.invalid)) }
                validSelectedPool = nil
                return self.fetchBakerPool(bakerId: bakerId)
            }
            .sink { [weak self] result in
                self?.handleBakerPoolResponse(result)
            }
            .store(in: &cancellables)
        
        $selectedPool
            .sink { [weak self] pool in
                guard let self = self else { return }
                self.validatorIdErrorMessage = nil
                if pool == .passive {
                    self.validatorId = ""
                    self.validSelectedPool = .passive
                    self.bottomMessage = "delegation.pool.passive.bottom.message".localized
                } else {
                    _ = self.resetToCurrentBakerPool()
                    self.bottomMessage = "delegation.pool.baker.bottom.message".localized
                }
            }
            .store(in: &cancellables)
        
        $validSelectedPool
            .map { (validPool) in
                return validPool != nil
            }
            .assign(to: &$isContinueEnabled)
    }

    func fetchBakerPool(bakerId: String) -> AnyPublisher<Result<Int, DelegationPoolBakerIdError>, Never> {
        self.validatorId = bakerId
        if bakerId.isEmpty {
            return .just(resetToCurrentBakerPool())
        }
        
        guard let bakerIdInt = Int(bakerId) else {
            return .just(Result.failure(DelegationPoolBakerIdError.invalid))
        }
        
        return stakeService.getBakerPool(bakerId: bakerIdInt)
            .map { response in
                self.bakerPoolResponse = response
                let currentBakerId = self.getCurrentBakerId()
                if (response.poolInfo.openStatus == "openForAll") ||
                   (response.poolInfo.openStatus == "closedForNew" && currentBakerId == bakerIdInt) {
                    return .success(bakerIdInt)
                } else {
                    return .failure(.closed)
                }
            }
            .replaceError(with: .failure(.invalid))
            .eraseToAnyPublisher()
    }

    func resetToCurrentBakerPool() -> Result<Int, DelegationPoolBakerIdError> {
        guard let currentPoolData: PoolDelegationData = (dataHandler.getNewEntry() ?? dataHandler.getCurrentEntry()) else {
            self.validatorId = ""
            self.validSelectedPool = nil

            return .failure(.empty)
        }
        if case let BakerTarget.bakerPool(bakerId) = currentPoolData.pool {
            self.validSelectedPool = currentPoolData.pool
            
            return .success(bakerId)
        } else {
            self.validatorId = ""
            self.validSelectedPool = nil
            
            return .failure(.empty)
        }
    }

    func getCurrentBakerId() -> Int? {
        guard let currentPoolData: PoolDelegationData = dataHandler.getCurrentEntry(),
              case let BakerTarget.bakerPool(bakerId) = currentPoolData.pool else {
            return nil
        }
        return bakerId
    }

    func handleBakerPoolResponse(_ result: Result<Int, DelegationPoolBakerIdError>) {
        guard selectedPool != .passive else { return }
        switch result {
        case .success(let validatorID):
            validSelectedPool = .bakerPool(bakerId: validatorID)
            validatorIdErrorMessage = nil
        case .failure(let error):
            validSelectedPool = nil
            switch error {
            case .empty:
                validatorIdErrorMessage = nil
            case .invalid:
                validatorIdErrorMessage = "delegation.pool.invalidbakerid".localized
            case .closed:
                validatorIdErrorMessage = "delegation.pool.closedpool".localized
            }
        }
    }
    
    func pressedContinue() {
        // the pool will be valid at this point as the buttonn is only enabled
        // if the pool is valid
        guard let validPool = self.validSelectedPool else { return }
        
        if case .bakerPool(let bakerId) = validPool {
            // we use whichever is available first, either the variable or
            // the response from the network
            Publishers.Merge(self.stakeService.getBakerPool(bakerId: bakerId),
                             self.$bakerPoolResponse
                                .compactMap { $0 }
                                .setFailureType(to: Error.self))
                .first()
                .sink(receiveError: { error in
                    self.alertOptions = AlertHelper.genericErrorAlertOptions(message: ErrorMapper.toViewError(error: error).errorDescription ?? error.localizedDescription)
                    withAnimation {
                        self.showAlert = true
                    }
                }, receiveValue: { bakerPoolResponse in
                    if self.shouldShowPoolSizeWarning(response: bakerPoolResponse) {
                        self.showPoolSizeWarning(response: bakerPoolResponse)
                    } else {
                        self.dataHandler.add(entry: PoolDelegationData(pool: validPool))
                        self.delegate?.finishedPoolSelection(
                            dataHandler: self.dataHandler,
                            bakerPoolResponse: bakerPoolResponse
                        )
                    }
                })
                .store(in: &cancellables)
        } else {
            self.dataHandler.add(entry: PoolDelegationData(pool: validPool))
            self.delegate?.finishedPoolSelection(
                dataHandler: self.dataHandler,
                bakerPoolResponse: nil
            )
        }
    }
    
    private func shouldShowPoolSizeWarning(response: BakerPoolResponse) -> Bool {
        // The alert should only be shown if you are not currently in cooldown and bakerId is different
        guard let delegation = self.account.delegation,
              delegation.pendingChange?.change == .NoChange,
              delegation.delegationTargetBakerID.string != validatorId else {
            return false
        }
        
        guard let poolLimit = GTU(intValue: Int(response.delegatedCapitalCap)),
              let delegatedCapital = GTU(intValue: Int(response.delegatedCapital)) else {
            return false
        }
        
        return GTU(intValue: delegation.stakedAmount) + delegatedCapital > poolLimit
    }
    
    private func showPoolSizeWarning(response: BakerPoolResponse) {
        let lowerAmountAction = SwiftUIAlertAction(
            name: "delegation.pool.sizewarning.loweramount".localized,
            completion: {
                self.delegate?.finishedPoolSelection(
                    dataHandler: self.dataHandler,
                    bakerPoolResponse: response
                )
            }, style: .plain
        )
        let stopDelegationAction = SwiftUIAlertAction(
            name: "delegation.pool.sizewarning.stopdelegation".localized,
            completion: {
                self.transactionService
                    .getTransferCost(transferType: .removeDelegation, costParameters: [])
                    .sink { error in
                        self.alertOptions = AlertHelper.genericErrorAlertOptions(message: ErrorMapper.toViewError(error: error).errorDescription ?? error.localizedDescription)
                        withAnimation {
                            self.showAlert = true
                        }
                    } receiveValue: { transferCost in
                        let cost = GTU(intValue: Int(transferCost.cost) ?? 0)
//                        self.delegate?.switchToRemoveDelegator(cost: cost, energy: transferCost.energy)
                    }
                    .store(in: &self.cancellables)

            }, style: .plain
        )
        let cancelAction = SwiftUIAlertAction(
            name: "delegation.pool.sizewarning.cancel".localized,
            completion: nil,
            style: .styled
        )
        
        let alertOptions = SwiftUIAlertOptions(
            title: "delegation.pool.sizewarning.title".localized,
            message: "delegation.pool.sizewarning.message".localized,
            actions: [lowerAmountAction, stopDelegationAction, cancelAction]
        )
        
        self.alertOptions = alertOptions

        withAnimation {
            self.showAlert = true
        }
    }
}


extension DelegationStakingModeViewModel: Equatable, Hashable {
    static func == (lhs: DelegationStakingModeViewModel, rhs: DelegationStakingModeViewModel) -> Bool {
        lhs.validatorId == rhs.validatorId &&
        lhs.selectedPool == rhs.selectedPool &&
        lhs.validatorIdErrorMessage == rhs.validatorIdErrorMessage &&
        lhs.bakerPoolResponse?.bakerID == rhs.bakerPoolResponse?.bakerID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(validatorId)
        hasher.combine(selectedPool)
        hasher.combine(validatorIdErrorMessage)
        hasher.combine(bakerPoolResponse?.bakerID)
    }
}
