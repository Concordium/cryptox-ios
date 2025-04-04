//
//  ValidatorTarget.swift
//  StagingNet
//
//  Created by Zhanna Komar on 04.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum ValidatorTarget: Equatable {
    case passive
    case bakerPool(bakerId: Int)
    
    func getDisplayValue() -> String {
        switch self {
        case .passive:
            return "delegation.receipt.passivevalue".localized
        case .bakerPool(let bakerId):
            return String(bakerId)
        }
    }
    
    static func from(delegationType: String, bakerId: Int?) -> ValidatorTarget {
        if let bakerId = bakerId, delegationType == "Baker" {
            return .bakerPool(bakerId: bakerId)
        } else {
            return .passive
        }
    }
}
