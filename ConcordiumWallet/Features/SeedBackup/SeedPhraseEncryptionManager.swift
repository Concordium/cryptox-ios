//
//  SeedPhraseEncryptionManager.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import CryptoKit

struct SeedPhraseEncryptionManager {
    
    // Derive a symmetric key from password
    private func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        let key = SymmetricKey(size: .bits256)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("encryption-seed".utf8),
            outputByteCount: 32
        )
        return derivedKey
    }
    
    func encryptSeed(_ seedPhrase: String, password: String) throws -> Data {
        let seedData = Data(seedPhrase.utf8)
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) }) // random 16-byte salt
        let nonce = AES.GCM.Nonce()
        let key = deriveKey(from: password, salt: salt)
        
        let sealedBox = try AES.GCM.seal(seedData, using: key, nonce: nonce)
        
        // Combine salt + nonce + ciphertext + tag into single blob
        var combined = Data()
        combined.append(salt)
        combined.append(contentsOf: nonce)
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)
        
        return combined
    }
    
    func decryptSeed(_ encryptedData: Data, password: String) throws -> String {
        // Extract salt (16 bytes), nonce (12 bytes), tag (16 bytes)
        let salt = encryptedData.subdata(in: 0..<16)
        let nonceData = encryptedData.subdata(in: 16..<28)
        let tag = encryptedData.suffix(16)
        let ciphertext = encryptedData.subdata(in: 28..<(encryptedData.count - 16))
        
        let key = deriveKey(from: password, salt: salt)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw DecryptionError.invalidData
        }
        return decryptedString
    }
    
    enum DecryptionError: Error {
        case invalidData
    }
}
