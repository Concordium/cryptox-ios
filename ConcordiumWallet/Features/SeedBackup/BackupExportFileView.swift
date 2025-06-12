//
//  BackupExportFileView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupExportView: UIViewControllerRepresentable {
    let backupFileURL: URL
    let onExportCompletion: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onCompletion: onExportCompletion)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [backupFileURL], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompletion: (Bool) -> Void

        init(onCompletion: @escaping (Bool) -> Void) {
            self.onCompletion = onCompletion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onCompletion(true)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCompletion(false)
        }
    }
}
