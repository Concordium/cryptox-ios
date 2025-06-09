//
//  ImportWalletPrivateKeyViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class ImportWalletPrivateKeyViewModel: ObservableObject {
    let onValidPrivateKey: (IdentifiableString) -> Void

    @Published var isValidPhrase: Bool = false
    @Published var currentInput: String = ""
    @Published var error: String? = nil
    var walletPrivateKey: IdentifiableString?
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private let dependencyProvider: ServicesProvider = .defaultProvider()
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPrivateKey: @escaping (IdentifiableString) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPrivateKey = onValidPrivateKey
    }
    
    func clearAll() {
        currentInput = ""
        isValidPhrase = false
        error = nil
    }
        
    func validateCurrentInput() {
        if !currentInput.isEmpty {
            if recoveryService.isValidWalletPrivateKey(key: currentInput) {
                walletPrivateKey = IdentifiableString(value: currentInput)
                isValidPhrase = true
                withAnimation {
                    error = nil
                }
            } else {
                withAnimation {
                    isValidPhrase = false
                    error = "recoveryphrase.recover.input.validationerror".localized
                }
            }
        }
    }
    
    func importAction() {
        if let walletPrivateKey {
            onValidPrivateKey(walletPrivateKey)
        }
    }
}
