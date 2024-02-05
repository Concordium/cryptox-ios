//
//  Environment.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 27.04.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

enum Environment: String, Codable {
    case main = "production"
    case test = "prod_testnet"
    case staging = "staging"
    case mock = "mock"
    
    static var current: Environment {
        #if MAINNET
        if UserDefaults.bool(forKey: "demomode.userdefaultskey".localized) == true {
            return .test
        }
        return .main
        #elseif TESTNET
        return .test
        #elseif STAGINGNET
        return .staging
        #else // Mock
        return .mock
        #endif
    }
}
