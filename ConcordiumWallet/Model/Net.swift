//
//  Net.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 27.04.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

enum Net: String, Codable {
    case mainnet = "Mainnet"
    case testnet = "Testnet"
    case stagenet = "Stagenet"
    
    static var current: Net {
    #if MAINNET
        if UserDefaults.bool(forKey: "demomode.userdefaultskey".localized) == true {
            return .testnet
        }
        return .mainnet
    #elseif TESTNET
        return .testnet
    #elseif STAGINGNET
        return .testnet
    #endif
    }
}
