//
//  BakerDataHandler.swift
//  ConcordiumWallet
//
//  Created by Ruxandra Nistor on 23/03/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

class BakerDataHandler: StakeDataHandler {
    enum Action {
        case register
        case updateBakerStake(BakerDataType, PoolInfo)
        case updatePoolSettings(BakerDataType, PoolInfo)
        case updateBakerKeys(BakerDataType, PoolInfo)
        case stopBaking
        case suspend(BakerDataType, PoolInfo)
        case resume(BakerDataType, PoolInfo)
    }
    
    let account: AccountDataType
    let id = UUID()
    
    init(account: AccountDataType, action: Action) {
        self.account = account
        switch action {
        case .register:
            super.init(transferType: .registerBaker)
            self.add(entry: BakerCreateAccountData(accountName: account.name, accountAddress: account.address))
        case let .updateBakerStake(currentSettings, poolInfo):
            super.init(
                transferType: .updateBakerStake,
                currentData: BakerDataHandler.buildCurrentData(
                    fromAccount: account,
                    currentSettings: currentSettings,
                    poolInfo: poolInfo
                )
            )
            self.add(entry: BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        case let .updatePoolSettings(currentSettings, poolInfo):
            super.init(
                transferType: .updateBakerPool,
                currentData: BakerDataHandler.buildCurrentData(
                    fromAccount: account,
                    currentSettings: currentSettings,
                    poolInfo: poolInfo
                )
            )
            self.add(entry: BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        case let .updateBakerKeys(currentSettings, poolInfo):
            super.init(
                transferType: .updateBakerKeys,
                currentData: BakerDataHandler.buildCurrentData(
                    fromAccount: account,
                    currentSettings: currentSettings,
                    poolInfo: poolInfo
                )
            )
            self.add(entry: BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        case .stopBaking:
            super.init(transferType: .removeBaker)
            self.add(entry: DelegationStopAccountData(accountName: account.name, accountAddress: account.address))
        case .suspend(_, _):
            super.init(transferType: .updateValidatorSuspendState)
            self.add(entry: BakerUpdateSuspend(isSuspended: true))
            self.add(entry: BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        case .resume(_, _):
            super.init(transferType: .updateValidatorSuspendState)
            self.add(entry: BakerUpdateSuspend(isSuspended: false))
            self.add(entry: BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        }
    }
    
    private static func buildCurrentData(
        fromAccount account: AccountDataType,
        currentSettings: BakerDataType,
        poolInfo: PoolInfo
    ) -> [FieldValue] {
        var currentData = [FieldValue]()
        currentData.append(BakerUpdateAccountData(accountName: account.name, accountAddress: account.address))
        currentSettings.addStakeData(to: &currentData)
        poolInfo.addStakeData(to: &currentData)
        return currentData
    }
    
    func getCurrentAmount() -> GTU? {
        return getNewEntry(BakerAmountData.self)?.amount
    }
}

private extension BakerDataType {
    func addStakeData(to set: inout [FieldValue]) {
        set.append(BakerAmountData(amount: GTU(intValue: stakedAmount)))
        set.append(RestakeBakerData(restake: restakeEarnings))
    }
}

private extension PoolInfo {
    func addStakeData(to set: inout [FieldValue]) {
        if let poolSettings = ValidatorPoolSetting(rawValue: openStatus) {
            set.append(BakerPoolSettingsData(poolSettings: poolSettings))
        }
        set.append(BakerMetadataURLData(metadataURL: metadataURL))
        set.append(BakerCommissionData(
            bakingRewardComission: commissionRates.bakingCommission,
            finalizationRewardComission: commissionRates.finalizationCommission,
            transactionComission: commissionRates.transactionCommission
        ))
    }
}
