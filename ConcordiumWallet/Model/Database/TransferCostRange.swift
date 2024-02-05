//
//  TransferCostRange.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 27.04.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

struct TransferCostRange {
    let min: TransferCost
    let max: TransferCost
    
    var minCost: GTU {
        GTU(intValue: Int(min.cost) ?? 0)
    }
    
    var maxCost: GTU {
        GTU(intValue: Int(max.cost) ?? 0)
    }
}
