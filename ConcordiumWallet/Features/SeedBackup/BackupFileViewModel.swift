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
    let onValidPhrase: (IdentifiableString) -> Void
    @Published var error: String? = nil
    @Published var isValidPhrase: Bool = false
    @Published var showImportButton: Bool = false
    @Published var backupFiles: [BackupFile] = []
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPhrase: @escaping (IdentifiableString) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPhrase = onValidPhrase
        loadBackupFiles()
    }

    func loadBackupFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let pkpassFiles = fileURLs.filter { $0.pathExtension == "pkpass" && $0.absoluteString.contains("cryptoX") }
            backupFiles = pkpassFiles.map { BackupFile(url: $0) }.sorted(by: { $0.name > $1.name })
        } catch {
            print("Error reading backup files: \(error)")
        }
    }
    
    func importAction(data: Data, pwHash: String) {
        do {
            let decrypted = try SeedPhraseEncryptionManager().decryptSeed(data, password: pwHash)
            print("Decrypted seed: \(decrypted)")
            if recoveryService.isValidWalletPrivateKey(key: decrypted) {
                let identifiableKey = IdentifiableString(value: decrypted)
                self.onValidPhrase(identifiableKey)
            } else {
                error = "recoveryphrase.recover.input.validationerror".localized
            }
        } catch {
            print("Error while importing backup file")
        }
    }
}
