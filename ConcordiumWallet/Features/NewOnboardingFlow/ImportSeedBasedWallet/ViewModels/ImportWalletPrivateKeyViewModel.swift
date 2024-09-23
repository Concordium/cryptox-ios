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
    let onValidPrivateKey: (RecoveryPhrase) -> Void

    @Published var isValidPhrase: Bool = false
    @Published var currentInput: String = ""
    @Published var error: String? = nil
    var seedPhrase: RecoveryPhrase?
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private let dependencyProvider: ServicesProvider = .defaultProvider()
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPrivateKey: @escaping (RecoveryPhrase) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPrivateKey = onValidPrivateKey
    }
    
    func clearAll() {
        currentInput = ""
        isValidPhrase = false
        error = nil
    }
        
    func validateCurrentInput() {
        if !currentInput.isEmpty,
           let decodedSeedPhrase = Data(hex: currentInput),
           let decodedPhrase = String(data: decodedSeedPhrase, encoding: .utf8)?.components(separatedBy: " ") {
            switch recoveryService.validate(recoveryPhrase: decodedPhrase) {
            case .success(let recoveryPhrase):
                isValidPhrase = true
                seedPhrase = recoveryPhrase
            case .failure:
                isValidPhrase = false
                error = "recoveryphrase.recover.input.validationerror".localized
            }
        } else if !currentInput.isEmpty {
            error = "recoveryphrase.recover.input.validationerror".localized
        } else {
            error = nil
        }
    }
    
    func importAction() {
        if let seedPhrase {
            onValidPrivateKey(seedPhrase)
        }
    }
}
