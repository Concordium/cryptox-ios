//
//  SeedPhraseBackupManager.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Security
import Compression
import CommonCrypto
import ZIPFoundation
import PassKit

final class SeedPhraseBackupManager {
    
    private func createPassJSON(with encryptedSeed: Data) -> Data {
        let base64Seed = encryptedSeed.base64EncodedString()
        let pass: [String: Any] = [
            "description": "Seed Backup",
            "formatVersion": 1,
            "organizationName": "CryptoX",
            "passTypeIdentifier": "pass.com.CryptoX.seedbackup",
            "serialNumber": UUID().uuidString,
            "generic": [
                "primaryFields": [
                    [
                        "key": "seed",
                        "label": "Encrypted Seed",
                        "value": base64Seed
                    ]
                ]
            ]
        ]
        
        return try! JSONSerialization.data(withJSONObject: pass, options: .prettyPrinted)
    }
    
    private func sha1Hash(of data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func makeBackupFileURL() -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = formatter.string(from: Date())
        
        let filename = "cryptoX_backup_\(dateString).pkpass"
        return documentsURL.appendingPathComponent(filename)
    }
    
    func createPKPassFile(encryptedSeed: Data) throws -> URL {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        defer { try? fileManager.removeItem(at: tempDirectory) }
        
        // Save seed file
        let seedFileURL = tempDirectory.appendingPathComponent("seed.json")
        try encryptedSeed.write(to: seedFileURL)
        
        // Generate pass.json
        let passData = createPassJSON(with: encryptedSeed)
        let passFileURL = tempDirectory.appendingPathComponent("pass.json")
        try passData.write(to: passFileURL)
        
        // Generate manifest
        let manifest: [String: String] = [
            "seed.json": sha1Hash(of: encryptedSeed),
            "pass.json": sha1Hash(of: passData)
        ]
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [])
        let manifestURL = tempDirectory.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestURL)
        
        // Create ZIP file
        let destinationURL = makeBackupFileURL()
        let archive = try Archive(url: destinationURL, accessMode: .create)
        try archive.addEntry(with: "seed.json", relativeTo: tempDirectory)
        try archive.addEntry(with: "pass.json", relativeTo: tempDirectory)
        try archive.addEntry(with: "manifest.json", relativeTo: tempDirectory)
        
        return archive.url
    }
    
    func saveToICloud(fileURL: URL) throws -> URL {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.pioneeringtechventures.cryptox") else {
            throw NSError(domain: "iCloudError", code: 1, userInfo: [NSLocalizedDescriptionKey: "iCloud not available"])
        }

        // Save into "Documents/Backups" inside iCloud Drive
        let destinationFolder = iCloudURL.appendingPathComponent("Documents/Backups", isDirectory: true)
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        let destinationURL = destinationFolder.appendingPathComponent(fileURL.lastPathComponent)
        try FileManager.default.copyItem(at: fileURL, to: destinationURL)

        return destinationURL
    }
}
