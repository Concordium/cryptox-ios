//
//  Net.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 27.04.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

enum Net: String, Codable {
    case main = "Mainnet"
    case test = "Testnet"
    
    static var current: Net {
        #if MAINNET
        if UserDefaults.bool(forKey: "demomode.userdefaultskey".localized) == true {
            return .test
        }
        return .main
        #else
        return .test
        #endif
    }
}
