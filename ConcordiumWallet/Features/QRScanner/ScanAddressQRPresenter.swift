//
//  ScanAddressQRPresenter.swift
//  ConcordiumWallet
//
//  SwiftUI sheet entry points for the QR scanner (address-only and full result).
//

import Foundation
import SwiftUI

// MARK: - SwiftUI sheet entry points

/// Address-only sheet (e.g. pick recipient).
struct ScanAddressQRView: View {
    var onPicked: (String) -> Void
    var dependencyProvider = ServicesProvider.defaultProvider()
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ScanAddressQRSheetContent(
            wallet: dependencyProvider.mobileWallet(),
            onPicked: onPicked,
            onDismiss: { dismiss() }
        )
    }
}

/// Full result sheet (address, airdrop, connect URL, WalletConnect) for home/toolbar.
struct ScanAddressQRViewWithResult: View {
    var onResult: (QRScannerOutput) -> Void
    var onDismiss: () -> Void
    var dependencyProvider = ServicesProvider.defaultProvider()
    @SwiftUI.Environment(\.dismiss) private var envDismiss

    var body: some View {
        ScanAddressQRSheetContentWithResult(
            wallet: dependencyProvider.mobileWallet(),
            onResult: onResult,
            onDismiss: { envDismiss(); onDismiss() }
        )
    }
}

private struct ScanAddressQRSheetContent: View {
    let wallet: MobileWalletProtocol
    let onPicked: (String) -> Void
    let onDismiss: () -> Void
    @State private var viewModel: ScanAddressQRViewModel

    init(wallet: MobileWalletProtocol, onPicked: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.wallet = wallet
        self.onPicked = onPicked
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: ScanAddressQRViewModel(wallet: wallet))
    }

    var body: some View {
        ScanAddressQRSwiftUIView(
            viewModel: viewModel,
            onResult: { onPicked($0.address) },
            onDismiss: onDismiss
        )
    }
}

private struct ScanAddressQRSheetContentWithResult: View {
    let wallet: MobileWalletProtocol
    let onResult: (QRScannerOutput) -> Void
    let onDismiss: () -> Void
    @State private var viewModel: ScanAddressQRViewModel

    init(wallet: MobileWalletProtocol, onResult: @escaping (QRScannerOutput) -> Void, onDismiss: @escaping () -> Void) {
        self.wallet = wallet
        self.onResult = onResult
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: ScanAddressQRViewModel(wallet: wallet))
    }

    var body: some View {
        ScanAddressQRSwiftUIView(
            viewModel: viewModel,
            onResult: onResult,
            onDismiss: onDismiss
        )
    }
}
