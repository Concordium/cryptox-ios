//
//  BakerPoolReceiptType.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 25/04/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

enum BakerPoolReceiptType {
    case updateStake(isLoweringStake: Bool)
    case updatePool
    case updateKeys
    case suspend
    case resume
    case remove
    case register
    
    init(dataHandler: StakeDataHandler) {
        switch dataHandler.transferType {
        case .registerBaker:
            self = .register
        case .updateBakerStake:
            self = .updateStake(isLoweringStake: dataHandler.isLoweringStake())
        case .updateBakerPool:
            self = .updatePool
        case .updateBakerKeys:
            self = .updateKeys
        case .updateValidatorSuspendState:
            if let suspendEntry = dataHandler.getNewEntry(BakerUpdateSuspend.self) {
                self =  suspendEntry.isSuspended ? .suspend : .resume
            } else {
                self = .remove
            }
        case .simpleTransfer:
            self = .remove
        case .transferToPublic:
            self = .remove
        case .transferUpdate:
            self = .remove
        case .registerDelegation:
            self = .remove
        case .updateDelegation:
            self = .remove
        case .removeDelegation:
            self = .remove
        case .removeBaker:
            self = .remove
        case .configureBaker:
            self = .remove
        }
    }
}
