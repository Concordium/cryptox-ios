//
//  WalletConnectConstants.swift
//  CryptoX
//
//  Created on 2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

/// Centralized WalletConnect configuration constants
enum WalletConnectConstants {
    /// Method for signing and sending transactions
    static let signAndSendTransaction = "sign_and_send_transaction"
    
    /// Method for signing messages
    static let signMessage = "sign_message"
    
    /// Method for requesting verifiable presentations (ID2.5)
    static let requestVerifiablePresentation = "request_verifiable_presentation"
    
    /// Method for requesting verifiable presentations v1 (auditable ZK proofs)
    static let requestVerifiablePresentationV1 = "request_verifiable_presentation_v1"
    
    /// All supported WalletConnect request methods
    static let allowedRequestMethods: [String] = [
        signAndSendTransaction,
        signMessage,
        requestVerifiablePresentation,
        requestVerifiablePresentationV1
    ]
    
    /// Check if a method is supported
    static func isMethodSupported(_ method: String) -> Bool {
        allowedRequestMethods.contains(method)
    }
}

