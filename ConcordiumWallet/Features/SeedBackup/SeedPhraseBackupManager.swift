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
    private let fileStorageURL = "Documents/"
    private let ubiquityContainerIdentifier = "iCloud.com.pioneeringtechventures.cryptox"
    
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
    
    private func getBackupFileURL(toICloud: Bool) -> URL? {
        let fileManager = FileManager.default

        var baseURL: URL?
        if toICloud {
            baseURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
                .appendingPathComponent(fileStorageURL)
        } else {
            baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        }

        guard let rootURL = baseURL else { return nil }

        var schemaName = ""
        #if MAINNET
            schemaName = "Mainnet"
        #elseif TESTNET
            schemaName = "Testnet"
        #endif

        let filename = "\(schemaName) backup_\(getFirstAccountName()).pkpass"
        return rootURL.appendingPathComponent(filename)
    }
    
    private func getFirstAccountName() -> String {
        return ServicesProvider.defaultProvider().storageManager().getAccounts().first?.displayName ?? ""

    }
    
    func createPKPassFileInICloud(
        encryptedSeed: Data,
        completion: @escaping (Result<URL, ICloudBackupError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default

            let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            do {
                try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
                defer { try? fileManager.removeItem(at: tempDirectory) }

                // Create seed.json
                let seedFileURL = tempDirectory.appendingPathComponent("seed.json")
                try encryptedSeed.write(to: seedFileURL)

                // Create pass.json
                let passData = self.createPassJSON(with: encryptedSeed)
                let passFileURL = tempDirectory.appendingPathComponent("pass.json")
                try passData.write(to: passFileURL)

                // Create manifest.json
                let manifest: [String: String] = [
                    "seed.json": self.sha1Hash(of: encryptedSeed),
                    "pass.json": self.sha1Hash(of: passData)
                ]
                let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [])
                let manifestURL = tempDirectory.appendingPathComponent("manifest.json")
                try manifestData.write(to: manifestURL)

                // Ensure iCloud URL exists
                guard let destinationURL = self.getBackupFileURL(toICloud: true) else {
                    completion(.failure(.iCloudNotAvailable))
                    return
                }

                let destinationFolder = destinationURL.deletingLastPathComponent()
                try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // Create archive directly in iCloud
                let archive = try Archive(url: destinationURL, accessMode: .create)
                try archive.addEntry(with: "seed.json", relativeTo: tempDirectory)
                try archive.addEntry(with: "pass.json", relativeTo: tempDirectory)
                try archive.addEntry(with: "manifest.json", relativeTo: tempDirectory)

                DispatchQueue.main.async {
                    completion(.success(archive.url))
                }

            } catch let error as ICloudBackupError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.failedToSave))
                }
            }
        }
    }

    func deleteAllICloudBackups() {
        guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?.appendingPathComponent(fileStorageURL) else {
            print("iCloud not available")
            return
        }

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: ubiquityURL, includingPropertiesForKeys: nil)

            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
                print("Deleted: \(fileURL.lastPathComponent)")
            }
        } catch {
            print("Failed to delete iCloud files: \(error)")
        }
    }
    
    func isBackupFileCreated() -> Bool {
        guard let backupURL = getBackupFileURL(toICloud: true) else {
            print("iCloud container URL not available")
            return false
        }
        
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: backupURL.path)
        print("Checking backup file existence at iCloud path: \(backupURL.path) - Exists: \(exists)")
        return exists
    }
}
