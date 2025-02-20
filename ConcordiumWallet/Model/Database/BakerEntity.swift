//
//  BakerEntity.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import RealmSwift

protocol BakerDataType: DataStoreProtocol {
    var bakerID: Int { get set }
    var stakedAmount: Int { get set }
    var restakeEarnings: Bool { get set }
    var bakerAggregationVerifyKey: String { get set }
    var bakerElectionVerifyKey: String { get set }
    var bakerSignatureVerifyKey: String { get set }
    var pendingChange: PendingChangeDataType? { get set }
    var isSuspended: Bool { get set }
}

final class BakerEntity: Object {
    @objc dynamic var bakerID: Int = -1
    @objc dynamic var stakedAmount: Int = 0
    @objc dynamic var restakeEarnings: Bool = false
    @objc dynamic var bakerAggregationVerifyKey: String = ""
    @objc dynamic var bakerElectionVerifyKey: String = ""
    @objc dynamic var bakerSignatureVerifyKey: String = ""
    @objc dynamic var pendingChangeEntity: PendingChangeEntity?
    @objc dynamic var isSuspended: Bool = false
        
    convenience init(accountBakerModel: AccountBaker) {
        self.init()
        self.bakerID = accountBakerModel.bakerID
        self.stakedAmount = Int(accountBakerModel.stakedAmount) ?? 0
        self.restakeEarnings = accountBakerModel.restakeEarnings
        self.bakerAggregationVerifyKey = accountBakerModel.bakerAggregationVerifyKey
        self.bakerElectionVerifyKey = accountBakerModel.bakerElectionVerifyKey
        self.bakerSignatureVerifyKey = accountBakerModel.bakerSignatureVerifyKey
        self.pendingChangeEntity = PendingChangeEntity(pendingChange: accountBakerModel.pendingChange)
        self.isSuspended = accountBakerModel.isSuspended
    }
}

extension BakerEntity: BakerDataType {
    var pendingChange: PendingChangeDataType? {
        get {
            pendingChangeEntity
        }
        set {
            self.pendingChangeEntity = newValue as? PendingChangeEntity
        }
    }
}
