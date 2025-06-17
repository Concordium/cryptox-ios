//
//  RecoveryPhraseService.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 30/06/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import MnemonicSwift
import Combine
import Foundation

protocol RecoveryPhraseServiceProtocol {
    func generateRecoveryPhrase() -> Result<RecoveryPhrase, Error>
    
    func generateSuggestions(from words: RecoveryPhrase, maxNumberOfSuggestions: Int) -> [[String]]
    
    func suggestions(for word: String) -> [String]
    
    func validate(recoveryPhrase: [String]) -> Result<RecoveryPhrase, Error>
    
    func store(recoveryPhrase: RecoveryPhrase, with pwHash: String) async throws -> Seed
    
    func store(walletPrivateKey: String, with pwHash: String) async throws -> Seed
    
    func isValidWalletPrivateKey(key: String) -> Bool
}

extension RecoveryPhraseServiceProtocol {
    func generateRecoveryPhrase() -> Result<RecoveryPhrase, Error> {
        return Result { try Mnemonic.generateMnemonic(strength: 24 / 3 * 32) }
            .flatMap { phrase in Result { try RecoveryPhrase(phrase: phrase) } }
    }
    
    func generateSuggestions(from recoveryPhrase: RecoveryPhrase, maxNumberOfSuggestions: Int) -> [[String]] {
        return recoveryPhrase.map { word in
            ([word] + recoveryPhrase.randomSequence(ofLength: maxNumberOfSuggestions - 1, skipping: word))
                .map { String($0) }
                .shuffled()
        }
    }
    
    func suggestions(for word: String) -> [String] {
        let lowercased = word.lowercased()
        
        let words = String.mnemonics.filter { $0.starts(with: lowercased) }
        
        return Array(words[0..<min(words.count, 4)])
    }
    
    func validate(recoveryPhrase: [String]) -> Result<RecoveryPhrase, Error> {
        return Result {
            let phrase = recoveryPhrase.joined(separator: " ")
            
            try Mnemonic.validate(mnemonic: phrase)
            
            return try RecoveryPhrase(phrase: phrase)
        }
    }
}

struct RecoveryPhraseService {
    private static let recoveryPhraseKey = "CCD.RecoveryPhrase"
    private let keychainWrapper: KeychainWrapperProtocol
    private let mobileWallet: SeedMobileWalletProtocol
    
    init(
        keychainWrapper: KeychainWrapperProtocol,
        mobileWallet: SeedMobileWalletProtocol
    ) {
        self.keychainWrapper = keychainWrapper
        self.mobileWallet = mobileWallet
    }
}

extension RecoveryPhraseService: RecoveryPhraseServiceProtocol {
    func store(recoveryPhrase: RecoveryPhrase, with pwHash: String) throws -> Seed {
        try mobileWallet.store(recoveryPhrase: recoveryPhrase, with: pwHash).get()
    }
    
    func store(walletPrivateKey: String, with pwHash: String) throws -> Seed {
        try mobileWallet.store(walletPrivateKey: walletPrivateKey, with: pwHash).get()
    }
}

private extension RandomAccessCollection where Element: Equatable {
    func randomSequence(ofLength length: Int, skipping elements: Element...) -> [Element] {
        var mutableCopy = Array(self)
        var result = [Element]()
        while !mutableCopy.isEmpty && result.count < length {
            let index = Int.random(in: 0..<mutableCopy.count)
            let value = mutableCopy.remove(at: index)
            if !elements.contains(value) {
                result.append(value)
            }
        }
        
        return result
    }
}

extension RecoveryPhraseServiceProtocol {
    func isValidWalletPrivateKey(key: String) -> Bool {
        let hexPattern = "^[0-9a-fA-F]{128}$"
        
        do {
            let regex = try NSRegularExpression(pattern: hexPattern)
            let range = NSRange(location: 0, length: key.utf16.count)
            
            if regex.firstMatch(in: key, options: [], range: range) != nil {
                let decodedBytes = try hexStringToByteArray(key)
                return decodedBytes.count == 64
            } else {
                return false
            }
        } catch {
            return false
        }
    }


    
    private func hexStringToByteArray(_ hex: String) throws -> [UInt8] {
        guard hex.count % 2 == 0 else {
            throw NSError(domain: "Invalid hex string: length must be even", code: 0, userInfo: nil)
        }

        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            } else {
                throw NSError(domain: "Invalid hex string", code: 0, userInfo: nil)
            }
            
            index = nextIndex
        }
        return bytes
    }
}
