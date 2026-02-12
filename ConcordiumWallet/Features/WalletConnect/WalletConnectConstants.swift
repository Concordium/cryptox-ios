//
//  WalletConnectConstants.swift
//  CryptoX
//
//  Created on 2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

/// Centralized WalletConnect configuration constants
enum WalletConnectConstants: String, CaseIterable {
    /// Method for signing and sending transactions
    case signAndSendTransaction = "sign_and_send_transaction"
    
    /// Method for signing messages
    case signMessage = "sign_message"
    
    /// Method for requesting verifiable presentations (ID2.5)
    case requestVerifiablePresentation = "request_verifiable_presentation"
    
    /// Method for requesting verifiable presentations v1 (auditable ZK proofs)
    case requestVerifiablePresentationV1 = "request_verifiable_presentation_v1"
    
    /// Sponsored Transactions
    case signAndSendSponsoredTransaction = "sign_and_send_sponsored_transaction"
    
    /// All supported WalletConnect request methods as strings
    static var allowedRequestMethods: [String] {
        allCases.map(\.rawValue)
    }
    
    /// Check if a method is supported
    static func isMethodSupported(_ method: String) -> Bool {
        allCases.contains { $0.rawValue == method }
    }
    
    /// Initialize from a string method name
    init?(method: String) {
        self.init(rawValue: method)
    }
}

