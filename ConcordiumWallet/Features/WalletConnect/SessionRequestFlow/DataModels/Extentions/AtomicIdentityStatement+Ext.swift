//
//  AtomicIdentityStatement+Ext.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

extension AtomicIdentityStatement {
    var groupTitle: String {
        switch self {
        case .revealAttribute:
            return "Information to reveal"
        case .attributeInRange, .attributeInSet, .attributeNotInSet:
            return "Zero-knowledge proof"
        }
    }
}
