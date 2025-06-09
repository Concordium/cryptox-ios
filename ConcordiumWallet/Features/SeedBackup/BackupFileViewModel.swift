//
//  BackupFileViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

struct BackupFile: Identifiable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
}

final class BackupFileViewModel: ObservableObject {
    let onValidPhrase: (RecoveryPhrase) -> Void
    @Published var error: String? = nil
    @Published var isValidPhrase: Bool = false
    @Published var showImportButton: Bool = false
    @Published var backupFiles: [BackupFile] = []
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPhrase: @escaping (RecoveryPhrase) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPhrase = onValidPhrase
        loadFilesFromIcloud()
    }
    
    func loadFilesFromIcloud() {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.pioneeringtechventures.cryptox") else {
            print("iCloud not available or container not found")
            return
        }

        let documentsURL = iCloudURL.appendingPathComponent("Documents/Backups")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let pkpassFiles = contents.filter { $0.pathExtension == "pkpass" && $0.absoluteString.contains("cryptoX") }
            
            for fileURL in pkpassFiles {
                try ensureFileIsDownloaded(at: fileURL)
                print("Ready to use: \(fileURL.lastPathComponent)")
            }
            backupFiles = pkpassFiles.map { BackupFile(url: $0) }.sorted(by: { $0.name > $1.name })
        } catch {
            print("Failed to list iCloud documents: \(error)")
        }
    }
    
    func importAction(url: URL, pwHash: String) {
        do {
            let seedPhrase = try SeedPhraseEncryptionManager().decryptBackupFile(at: url)
            print("Decrypted seed: \(seedPhrase)")
            switch recoveryService.validate(recoveryPhrase: seedPhrase.components(separatedBy: " ")) {
            case .success:
                let recoveryPhrase = try RecoveryPhrase(phrase: seedPhrase)
                self.onValidPhrase(recoveryPhrase)
            case .failure:
                error = "recoveryphrase.recover.input.validationerror".localized
            }
        } catch {
            print("Error while importing backup file")
        }
    }
    
    private func ensureFileIsDownloaded(at url: URL) throws {
        let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        
        if let status = resourceValues.ubiquitousItemDownloadingStatus {
            switch status {
            case .notDownloaded:
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            case .current, .downloaded:
                // File is available
                break
            default:
                break
            }
        }
    }
}
