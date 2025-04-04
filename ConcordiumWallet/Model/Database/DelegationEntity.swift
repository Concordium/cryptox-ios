//
//  DelegationEntity.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import RealmSwift

protocol DelegationDataType: DataStoreProtocol {
    var stakedAmount: Int { get set}
    var restakeEarnings: Bool { get set}
    var delegationTargetType: String { get set}
    var delegationTargetBakerID: Int { get set}
    var pendingChange: PendingChangeDataType? { get set }
    var isSuspended: Bool { get set }
    var isPrimedForSuspension: Bool { get set }
}

final class DelegationEntity: Object {
    @objc dynamic var stakedAmount: Int = 0
    @objc dynamic var restakeEarnings: Bool = false
    @objc dynamic var delegationTargetType: String = ""
    @objc dynamic var delegationTargetBakerID: Int = -1
    @objc dynamic var pendingChangeEntity: PendingChangeEntity?
    @objc dynamic var isSuspended: Bool = false
    @objc dynamic var isPrimedForSuspension: Bool = false
    
    convenience init(accountDelegationModel: AccountDelegation) {
        self.init()
        self.stakedAmount = Int(accountDelegationModel.stakedAmount) ?? 0
        self.restakeEarnings = accountDelegationModel.restakeEarnings
        self.delegationTargetType = accountDelegationModel.delegationTarget.delegateType
        self.delegationTargetBakerID = accountDelegationModel.delegationTarget.bakerID ?? -1
        self.pendingChangeEntity = PendingChangeEntity(pendingChange: accountDelegationModel.pendingChange)
        self.isSuspended = accountDelegationModel.isSuspended ?? false
        self.isPrimedForSuspension = accountDelegationModel.isPrimedForSuspension ?? false
    }
}

extension DelegationEntity: DelegationDataType {
    var pendingChange: PendingChangeDataType? {
        get {
            pendingChangeEntity
        }
        set {
            self.pendingChangeEntity = newValue as? PendingChangeEntity
        }
    }
}

extension DelegationDataType {
    var isInCooldown: Bool {
        if let pendingChange = pendingChange, pendingChange.change != .NoChange {
            return true
        } else {
            return false
        }
    }
}
