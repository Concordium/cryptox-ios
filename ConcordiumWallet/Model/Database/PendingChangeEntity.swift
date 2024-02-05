//
//  PendingChangeEntity.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import RealmSwift

protocol PendingChangeDataType: DataStoreProtocol {
    var change: AccountPendingChangeType { get set}
    var updatedNewStake: String? { get set}
    var effectiveTime: String? { get set}
    var estimatedChangeTime: String? { get set }
}

final class PendingChangeEntity: Object {
    @objc dynamic var changeString = ""
    @objc dynamic var updatedNewStake: String?
    @objc dynamic var effectiveTime: String?
    @objc dynamic var estimatedChangeTime: String?
    
    convenience init?(pendingChange: PendingChange?) {
        self.init()
        guard let pendingChange = pendingChange else {
            return
        }
        changeString = pendingChange.change
        updatedNewStake = pendingChange.newStake
        effectiveTime = pendingChange.effectiveTime
        estimatedChangeTime = pendingChange.estimatedChangeTime
    }
}

extension PendingChangeEntity: PendingChangeDataType {
    
    var change: AccountPendingChangeType {
        get {
            AccountPendingChangeType(rawValue: changeString) ?? .NoChange
        }
        set {
            changeString = newValue.rawValue
        }
    }
    
}
