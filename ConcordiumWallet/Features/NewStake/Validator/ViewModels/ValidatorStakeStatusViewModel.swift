//
//  ValidatorStakeStatusViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

final class ValidatorStakeStatusViewModel: ObservableObject {
    @Published var rows: [StakeRowViewModel] = []
    @Published var error: StakeStatusViewModelError?
    @Published var accountCooldowns: [AccountCooldown] = []
    @Published var stopButtonShown: Bool = true
    @Published var updateButtonEnabled: Bool = true
    @Published var title: String = ""
    @Published var topText: String = ""
    @Published var topImageName: String = ""
    @Published var placeholderText: String?
    
    private var dataHandler: StakeDataHandler?
    private let account: AccountDataType
    private lazy var status: BakerPoolStatus = .pendingTransfer
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
        self.status = getStatusViewModel() ?? .pendingTransfer
        setup(with: status)
    }
    
    func actionItems() -> [ActionItem] {
        var actionItems = [ActionItem]()
        if stopButtonShown {
            actionItems.append(ActionItem(iconName: "Stop", label: "Stop", action: {
                // navigate to the stop flow
            }))
        }
        actionItems.append(ActionItem(iconName: "ArrowsClockwise", label: "Update", action: { [weak self] in
            self?.updateTapped()
        }))
        return actionItems
    }
    
    private func updateTapped() {
        if let poolInfo = poolInfo, case let .registered(currentSettings) = status, let account = account as? AccountEntity {
            navigationManager.navigate(to: .updateValidatorMenu(ValidatorUpdateMenuViewModel(poolInfo: poolInfo, baker: currentSettings, navigationManager: navigationManager, account: account)))
        }
    }
}

// MARK: - Setup methods
extension ValidatorStakeStatusViewModel {
    private func setup(with status: BakerPoolStatus) {
        self.status = status
        if case let .registered(currentSettings) = status {
            stakeService.getBakerPool(bakerId: currentSettings.bakerID)
                .sink { [weak self] error in
                    self?.error = StakeStatusViewModelError(error)
                } receiveValue: { [weak self] bakerPoolResponse in
                    guard let self = self else { return }
                    self.poolInfo = bakerPoolResponse.poolInfo
                    self.setup(
                        withAccount: self.account,
                        currentSettings: currentSettings,
                        poolInfo: bakerPoolResponse.poolInfo
                    )
                }
                .store(in: &cancellables)

        } else {
            setupPending(withAccount: account)
        }
    }
    
    func setup(
        withAccount account: AccountDataType,
        currentSettings: BakerDataType,
        poolInfo: PoolInfo
    ) {
        var updatedRows: [FieldValue] = [
            BakerAccountData(accountName: account.name, accountAddress: account.address),
            BakerAmountData(amount: GTU(intValue: currentSettings.stakedAmount)),
            BakerIDData(id: currentSettings.bakerID),
            RestakeBakerData(restake: currentSettings.restakeEarnings)
        ]
        
        if let poolSetting = BakerPoolSetting(rawValue: poolInfo.openStatus) {
            updatedRows.append(BakerPoolSettingsData(poolSettings: poolSetting))
        }
        
        if !poolInfo.metadataURL.isEmpty {
            updatedRows.append(BakerMetadataURLData(metadataURL: poolInfo.metadataURL))
        }

        updateButtonEnabled = true
        accountCooldowns = account.cooldowns.map({AccountCooldown(timestamp: $0.timestamp, amount: $0.amount, status: $0.status.rawValue)})
        rows = updatedRows.flatMap { $0.getDisplayValues(type: .configureBaker).map { StakeRowViewModel(displayValue: $0) } }
    }
    
    func setupPending(withAccount account: AccountDataType) {
        title = "baking.status.title".localized
        topImageName = "logo_rotating_arrows"
        topText = "baking.status.waiting.header".localized
        placeholderText = "baking.status.waiting.placeholder".localized
        
        updateButtonEnabled = false
        stopButtonShown = false
        rows = []
    }
}

// MARK: - Status handling
extension ValidatorStakeStatusViewModel {
    
    func getStatusViewModel() -> BakerPoolStatus? {
        if dependencyProvider.storageManager().hasPendingBakerRegistration(for: account.address) {
            return .pendingTransfer
        } else if let currentSettings = account.baker {
            return .registered(currentSettings: currentSettings)
        }
        return nil
    }
    
    func updateStatus() {
        storageManager.getTransfers(for: account.address)
            .filter { $0.transferType.isBakingTransfer }
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transfer -> AnyPublisher<TransferDataType, Error> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.accountsService
                    .getLocalTransferWithUpdatedStatus(
                        transfer: transfer,
                        for: self.account
                    )
            }
            .collect()
            .zip(accountsService.recalculateAccountBalance(account: account, balanceType: .total))
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] (transfers, account) in
                    if !transfers.isEmpty {
                        self?.setup(with: .pendingTransfer)
                    } else if let currentSettings = account.baker {
                        self?.setup(with: .registered(currentSettings: currentSettings))
                    }
                }
            )
            .store(in: &cancellables)
    }
}

extension ValidatorStakeStatusViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorStakeStatusViewModel, rhs: ValidatorStakeStatusViewModel) -> Bool {
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
