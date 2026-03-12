//
//  ScanAddressQRViewModel.swift
//  ConcordiumWallet
//
//

import Foundation
import UIKit

/// Result type emitted when a QR code is successfully validated.
public enum QRScannerOutput {
    case address(String)
    case airdrop(String)
    case connectURL(String)
    case walletConnectV2(String)

    public var address: String {
        switch self {
        case .address(let s), .airdrop(let s), .connectURL(let s), .walletConnectV2(let s): return s
        }
    }
}

enum QRScanResult {
    case valid(QRScannerOutput)
    case invalid(dismissAfterDelay: Bool)
}

final class ScanAddressQRViewModel {
    private let wallet: MobileWalletProtocol
    private var lastInvalidString: String?

    init(wallet: MobileWalletProtocol) {
        self.wallet = wallet
    }

    /// Process a scanned QR string. Returns the result; view handles UI and callbacks.
    func process(_ string: String) -> QRScanResult {
        if wallet.check(accountAddress: string) {
            return .valid(.address(string))
        }
        if let url = URL(string: string), url.scheme == "airdrop" {
            return .valid(.airdrop(string))
        }
        if string.hasPrefix("wc:") {
            return .valid(.walletConnectV2(string))
        }
        if let uri = extractWalletConnectURI(from: string) {
            return .valid(.walletConnectV2(uri))
        }
        if let url = URL(string: string), UIApplication.shared.canOpenURL(url) {
            return .valid(.connectURL(string))
        }
        if lastInvalidString != string {
            lastInvalidString = string
            return .invalid(dismissAfterDelay: true)
        }
        return .invalid(dismissAfterDelay: false)
    }

    private func extractWalletConnectURI(from string: String) -> String? {
        guard let url = URL(string: string),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        guard let uriItem = queryItems.first(where: { $0.name == "uri" }),
              let uriValue = uriItem.value else { return nil }
        if uriValue.hasPrefix("wc:") { return uriValue }
        if let decoded = uriValue.removingPercentEncoding, decoded.hasPrefix("wc:") { return decoded }
        return nil
    }
}
