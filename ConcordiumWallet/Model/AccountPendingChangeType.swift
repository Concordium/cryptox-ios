//
//  AccountPendingChangeType.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

enum AccountPendingChangeType: String, Codable {
    case NoChange
    case ReduceStake
    case RemoveStake
}
