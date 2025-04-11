//
//  ValidatorPoolStatus.swift
//  StagingNet
//
//  Created by Zhanna Komar on 04.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum ValidatorPoolStatus: Equatable, Hashable {
    case pendingTransfer
    case registered(currentSettings: BakerDataType)
    
    static func == (lhs: ValidatorPoolStatus, rhs: ValidatorPoolStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pendingTransfer, .pendingTransfer):
            return true
        case let (.registered(lhsSettings), .registered(rhsSettings)):
            return lhsSettings.bakerID == rhsSettings.bakerID
        default:
            return false
        }
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }
}
