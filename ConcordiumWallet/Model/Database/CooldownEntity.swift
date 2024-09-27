//
//  CooldownEntity.swift
//  CryptoX
//
//  Created by Zhanna Komar on 25.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import RealmSwift

enum CooldownStatus: String {
    case cooldown
    case precooldown
    case preprecooldown
}

protocol CooldownDataType: DataStoreProtocol {
    var timestamp: Int { get set }
    var amount: String { get set }
    var status: CooldownStatus  { get set }
}

final class CooldownEntity: Object {
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var amount: String = ""
    @objc dynamic var statusString: String = CooldownStatus.preprecooldown.rawValue
    
    convenience init(accountCooldownModel: AccountCooldown) {
        self.init()
        self.timestamp = accountCooldownModel.timestamp
        self.amount = accountCooldownModel.amount
        self.statusString = accountCooldownModel.status
    }
}

extension CooldownEntity: CooldownDataType {  
    var status: CooldownStatus {
        get {
            CooldownStatus(rawValue: statusString) ?? .preprecooldown
        }
        set {
            statusString = newValue.rawValue
        }
    }
}
