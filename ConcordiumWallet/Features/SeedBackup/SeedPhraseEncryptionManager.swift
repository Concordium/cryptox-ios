//
//  SeedPhraseEncryptionManager.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import CryptoKit
import ZIPFoundation

struct SeedPhraseEncryptionManager {
    
    // Derive a symmetric key from password
    private func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
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
        combined.append(contentsOf: nonce.withUnsafeBytes { Data($0) })
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)
        
        print("Salt: \(salt.base64EncodedString())")
        print("Nonce: \(nonce.withUnsafeBytes { Data($0) }.base64EncodedString())")
        print("Ciphertext: \(sealedBox.ciphertext.base64EncodedString())")
        print("Tag: \(sealedBox.tag.base64EncodedString())")
        
        return combined
    }
    
    func decryptSeed(_ encryptedData: Data, password: String? = nil) throws -> String {
        // Extract salt (16 bytes), nonce (12 bytes), tag (16 bytes)
        let salt = encryptedData.subdata(in: 0..<16)
        let nonceData = encryptedData.subdata(in: 16..<28)
        let tag = encryptedData.suffix(16)
        let ciphertext = encryptedData.subdata(in: 28..<(encryptedData.count - 16))

        // Use a default password if none is provided
        let actualPassword = password ?? "pwHash"
        
        let key = deriveKey(from: actualPassword, salt: salt)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        
        print("Salt: \(salt.base64EncodedString())")
        print("Nonce: \(nonceData.base64EncodedString())")
        print("Ciphertext: \(ciphertext.base64EncodedString())")
        print("Tag: \(tag.base64EncodedString())")
        
        do {
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw DecryptionError.invalidData
            }
            return decryptedString
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    func decryptBackupFile(at url: URL) throws -> String {
        // Unzip the file (you can use ZIPFoundation or similar)
        let archive = try Archive(url: url, accessMode: .read)
        
        // Extract "seed.json" entry
        guard let entry = archive["seed.json"] else {
            throw NSError(domain: "Decryption", code: 1, userInfo: [NSLocalizedDescriptionKey: "seed.json not found"])
        }
        
        var seedData = Data()
        _ = try archive.extract(entry, consumer: { data in
            seedData.append(data)
        })

        // Decrypt it
        let manager = SeedPhraseEncryptionManager()
        let decrypted = try manager.decryptSeed(seedData, password: "pwHash")

        return decrypted
    }
    
    enum DecryptionError: Error {
        case invalidData
    }
}
