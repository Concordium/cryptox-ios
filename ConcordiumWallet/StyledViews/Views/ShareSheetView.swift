//
//  ShareSheetView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let fileURL: URL
    let completion: (Bool) -> Void

    class Coordinator: NSObject, UIActivityItemSource {
        let fileURL: URL
        let completion: (Bool) -> Void

        init(fileURL: URL, completion: @escaping (Bool) -> Void) {
            self.fileURL = fileURL
            self.completion = completion
        }

        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            return fileURL
        }

        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            return fileURL
        }

        func activityViewController(_ activityViewController: UIActivityViewController, didFinishWith activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) {
            completion(completed)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(fileURL: fileURL, completion: completion)
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            context.coordinator.completion(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
