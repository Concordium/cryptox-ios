//
//  ActivityView.swift
//  StagingNet
//
//  Created by Maksym Rachytskyy on 03.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct ShareText: Identifiable {
    let id = UUID()
    let text: String
}

struct ActivityView: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
