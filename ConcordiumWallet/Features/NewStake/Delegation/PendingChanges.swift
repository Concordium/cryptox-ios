//
//  PendingChanges.swift
//  StagingNet
//
//  Created by Zhanna Komar on 04.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum PendingChanges {
    case none
    case newDelegationAmount(coolDownEndTimestamp: String, newDelegationAmount: GTU)
    case stoppedDelegation(coolDownEndTimestamp: String)
    case poolWasDeregistered(coolDownEndTimestamp: String)
}
