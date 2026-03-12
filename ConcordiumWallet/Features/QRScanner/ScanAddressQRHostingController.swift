//
//  ScanAddressQRHostingController.swift
//  ConcordiumWallet
//
//  Hosts the SwiftUI QR scanner; conforms to ScanAddressQRScannerDismissible for coordinator integration.
//

import SwiftUI
import UIKit

enum ScanAddressQRFactory {
    /// Push flow: wallet + callback. ViewModel owns validation; this only hosts the view.
    static func create(wallet: MobileWalletProtocol, onResult: @escaping (QRScannerOutput) -> Void) -> ScanAddressQRHostingController {
        ScanAddressQRHostingController(wallet: wallet, onResult: onResult)
    }
}

private final class ScanAddressQRDismissCallback {
    var onDismiss: (() -> Void)?
}

final class ScanAddressQRHostingController: UIHostingController<ScanAddressQRSwiftUIView>, ScanAddressQRScannerDismissible {
    private let dismissCallback = ScanAddressQRDismissCallback()

    init(wallet: MobileWalletProtocol, onResult: @escaping (QRScannerOutput) -> Void) {
        let viewModel = ScanAddressQRViewModel(wallet: wallet)
        let view = ScanAddressQRSwiftUIView(
            viewModel: viewModel,
            onResult: onResult,
            onDismiss: { [dismissCallback] in
                dismissCallback.onDismiss?()
            }
        )
        super.init(rootView: view)
        dismissCallback.onDismiss = { [weak self] in
            self?.dismissScanner()
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func dismissScanner() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else if let nav = navigationController {
            if nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                nav.dismiss(animated: true)
            }
        }
    }
}
