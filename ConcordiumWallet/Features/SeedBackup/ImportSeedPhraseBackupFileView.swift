//
//  ImportSeedPhraseBackupFileView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ImportSeedPhraseBackupFileView: View {
    @StateObject private var viewModel = BackupFileViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.backupFiles) { file in
                HStack {
                    Text(file.name)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        shareBackup(file.url)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Backups")
        }
    }

    func shareBackup(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
