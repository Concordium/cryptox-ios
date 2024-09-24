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
            if validateWalletPrivateKey() {
                walletPrivateKey = IdentifiableString(value: currentInput)
                isValidPhrase = true
                error = nil
            } else {
                error = "recoveryphrase.recover.input.validationerror".localized
            }
        }
    }
    
    func importAction() {
        if let walletPrivateKey {
            onValidPrivateKey(walletPrivateKey)
        }
    }
    
    private func validateWalletPrivateKey() -> Bool {
        let hexPattern = "^[0-9a-fA-F]{128}$"
        
        do {
            let regex = try NSRegularExpression(pattern: hexPattern)
            let range = NSRange(location: 0, length: currentInput.utf16.count)
            
            if regex.firstMatch(in: currentInput, options: [], range: range) != nil {
                let decodedBytes = try hexStringToByteArray(currentInput)
                return decodedBytes.count == 64
            } else {
                return false
            }
        } catch {
            return false
        }
    }


    
    private func hexStringToByteArray(_ hex: String) throws -> [UInt8] {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let byteString = String(hex[index..<hex.index(index, offsetBy: 2)])
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            } else {
                throw NSError(domain: "Invalid hex string", code: 0, userInfo: nil)
            }
            index = hex.index(index, offsetBy: 2)
        }
        return bytes
    }

}
