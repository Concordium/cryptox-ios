//
//  ScanAddressQRPresenter.swift
//  ConcordiumWallet
//
//  Created by Concordium on 16/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import SwiftUI

public enum QRScannerOutput {
    case address(String)
    case airdrop(String)
    case connectURL(String)
    case walletConnectV2(String)
    
    public var address: String {
        switch self {
            case .address(let string): return string
            case .airdrop(let string): return string
            case .connectURL(let string): return string
            case .walletConnectV2(let string): return string
        }
    }
}

// MARK: View
protocol ScanAddressQRViewProtocol: AnyObject {
    func showQrValid()
    func showQrInvalid()
}

// MARK: -
// MARK: Delegate
protocol ScanAddressQRPresenterDelegate: AnyObject {
    func scanAddressQr(didScan output: QRScannerOutput)
}

// MARK: -
// MARK: Presenter
protocol ScanAddressQRPresenterProtocol: AnyObject {
	var view: ScanAddressQRViewProtocol? { get set }
    func viewDidLoad()
    func scannedQrCode(_: String)
}

class ScanAddressQRPresenter: ScanAddressQRPresenterProtocol {

    weak var view: ScanAddressQRViewProtocol?
    weak var delegate: ScanAddressQRPresenterDelegate?
    
    var closure: ((QRScannerOutput) -> Void)?
    
    let wallet: MobileWalletProtocol
    
    private var lastSaveErrorDisplayedString: String?

    init(wallet: MobileWalletProtocol, delegate: ScanAddressQRPresenterDelegate? = nil) {
        self.delegate = delegate
        self.wallet = wallet
    }
    
    init(wallet: MobileWalletProtocol, closure: ((QRScannerOutput) -> Void)? = nil) {
        self.closure = closure
        self.wallet = wallet
    }

    func viewDidLoad() {}
    
    func scannedQrCode(_ address: String) {
        Task {
            let qrValid = await wallet.check(accountAddress: address)
            await MainActor.run {
                if qrValid {
                    view?.showQrValid()
                    self.delegate?.scanAddressQr(didScan: .address(address))
                    self.closure?(.address(address))
                } else if let url = URL(string: address), let scheme = url.scheme, scheme == "airdrop" {
                    view?.showQrValid()
                    self.delegate?.scanAddressQr(didScan: .airdrop(address))
                    self.closure?(.airdrop(address))
                } else if address.hasPrefix("wc:") {
                    view?.showQrValid()
                    self.delegate?.scanAddressQr(didScan: .walletConnectV2(address))
                    self.closure?(.walletConnectV2(address))
                } else if URL(string: address) != nil {
                    view?.showQrValid()
                    self.delegate?.scanAddressQr(didScan: .connectURL(address))
                    self.closure?(.connectURL(address))
                } else {
                    if lastSaveErrorDisplayedString != address {
                        self.lastSaveErrorDisplayedString = address
                        view?.showQrInvalid()
                    }
                }
            }
        }
    }
}

struct ScanAddressQRView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController
    
    var dependencyProvider = ServicesProvider.defaultProvider()
    var onPicked: (String) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), closure: { output in
            onPicked(output.address)
            navigationController.popViewController(animated: true)
        }))
        navigationController.pushViewController(vc, animated: false)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No need to update anything dynamically
    }
}
