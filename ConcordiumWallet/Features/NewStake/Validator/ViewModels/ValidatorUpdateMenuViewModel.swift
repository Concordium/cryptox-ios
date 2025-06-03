//
//  ValidatorUpdateMenuViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 05.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

final class ValidatorUpdateMenuViewModel: ObservableObject {
    
    private let poolInfo: PoolInfo
    private let baker: BakerDataType
    private let navigationManager: NavigationManager
    private let account: AccountEntity
    
    init(poolInfo: PoolInfo, baker: BakerDataType, navigationManager: NavigationManager, account: AccountEntity) {
        self.poolInfo = poolInfo
        self.baker = baker
        self.navigationManager = navigationManager
        self.account = account
    }
    
    func updateStake() {
        let viewModel = ValidatorAmountInputViewModel(account: account,
                                                      dependencyProvider: ServicesProvider.defaultProvider(),
                                                      dataHandler: BakerDataHandler(account: account,
                                                                                    action: .updateBakerStake(baker, poolInfo)),
                                                      navigationManager: navigationManager)
        navigationManager.navigate(to: .amountInput(viewModel))
    }
    
    func updatePoolSettings() {
        let viewModel = ValidatorPoolSettingsViewModel(dataHandler: BakerDataHandler(account: account,
                                                                                     action: .updatePoolSettings(baker, poolInfo)),
                                                       navigationManager: navigationManager)
        navigationManager.navigate(to: .openningPool(viewModel))
    }
    
    func updateBakerKeys() {
        let viewModel = ValidatorGenerateKeysViewModel(dataHandler: BakerDataHandler(account: account,
                                                                                     action: .updateBakerKeys(baker, poolInfo)),
                                                       account: account,
                                                       dependencyProvider: ServicesProvider.defaultProvider())
        navigationManager.navigate(to: .generateKey(viewModel))
    }
}

extension ValidatorUpdateMenuViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorUpdateMenuViewModel, rhs: ValidatorUpdateMenuViewModel) -> Bool {
        lhs.poolInfo.metadataURL == rhs.poolInfo.metadataURL &&
        lhs.poolInfo.openStatus == rhs.poolInfo.openStatus &&
        lhs.baker.bakerID == rhs.baker.bakerID &&
        lhs.baker.restakeEarnings == rhs.baker.restakeEarnings &&
        lhs.baker.stakedAmount == rhs.baker.stakedAmount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(poolInfo.metadataURL)
        hasher.combine(poolInfo.openStatus)
        hasher.combine(baker.bakerID)
        hasher.combine(baker.restakeEarnings)
        hasher.combine(baker.stakedAmount)
    }
}
