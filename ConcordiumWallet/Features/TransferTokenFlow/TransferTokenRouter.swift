//
//  TransferTokenRouter.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 12.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import BigInt
import Combine

final class TransferTokenRouter: ObservableObject {
    private let rootController: UINavigationController
    private let account: AccountDataType
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let navigationController: UINavigationController
    private let navigationManager = NavigationManager()

    private var onAddressPicked = PassthroughSubject<String, Never>()
        
    init(
        root: UINavigationController,
        account: AccountDataType,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    ) {
        self.rootController = root
        self.account = account
        self.dependencyProvider = dependencyProvider
        self.navigationController = CXNavigationController()
        
        self.navigationController.hidesBottomBarWhenPushed = true
        self.navigationController.modalPresentationStyle = .overFullScreen
        root.present(self.navigationController, animated: true)
    }
    
    func dismissFlow() {
        rootController.dismiss(animated: true)
    }
    
    func showMemoWarningAlert(_ completion: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "warningAlert.transactionMemo.title".localized,
            message: "warningAlert.transactionMemo.text".localized,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(
            title: "errorAlert.okButton".localized,
            style: .default
        ) { _ in
            completion()
        }
        
        let dontShowAgain = UIAlertAction(
            title: "warningAlert.dontShowAgainButton".localized,
            style: .default
        ) { _ in
            AppSettings.dontShowMemoAlertWarning = true
            completion()
        }
        
        alert.addAction(okAction)
        alert.addAction(dontShowAgain)
        
        self.navigationController.present(alert, animated: true)
    }
    
    func showSimpleTransferConfirmFlow(
        data: SimpleTransferObject,
        onTxSuccess: @escaping (_ submissionId: String) -> Void,
        onTxReject: @escaping () -> Void
    ) {
        let tokenTransferModel = CIS2TokenTransferModel(
            tokenType: .ccd,
            account: account,
            dependencyProvider: dependencyProvider,
            notifyDestination: .legacyQrConnect,
            memo: nil,
            onTxSuccess: onTxSuccess,
            onTxReject: onTxReject
        )
        tokenTransferModel.amountTokenSend = .init(BigInt(stringLiteral: data.data.amount), 6)
        tokenTransferModel.recipient = data.data.to
        tokenTransferModel.tokenType = .ccd
        
        let viewModel: TransferTokenConfirmViewModel = .init(tokenTransferModel: tokenTransferModel, transactionsService: dependencyProvider.transactionsService(), storageManager: dependencyProvider.storageManager())
        let view = TransferSendingStatusView(viewModel: viewModel)
            .environmentObject(navigationManager)
        let viewController = SceneViewController(content: view)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    
}

extension TransferTokenRouter {
    func showQrAddressPicker(_ onPicked: @escaping (String) -> Void) {
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), closure: { [weak self] output in
            onPicked(output.address)
            self?.navigationController.popViewController(animated: true)
        }))
        DispatchQueue.main.async { [weak self] in
            self?.navigationController.pushViewController(vc, animated: true)
        }
    }
}
