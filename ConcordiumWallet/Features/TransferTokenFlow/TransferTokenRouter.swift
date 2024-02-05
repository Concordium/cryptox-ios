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
    
    func showSendTokenFlow(tokenType: CXTokenType) {
        let viewModel = TransferTokenViewModel(
            tokenType: tokenType,
            account: account,
            proxy: self,
            dependencyProvider: dependencyProvider,
            tokenTransferModel: CIS2TokenTransferModel(
                tokenType: tokenType,
                account: account,
                dependencyProvider: dependencyProvider,
                notifyDestination: .none,
                onTxSuccess: { _ in },
                onTxReject: {
                    
                }
            ), onRecipientPicked: onAddressPicked.eraseToAnyPublisher()
        )
        let view = TransferTokenView(viewModel: viewModel).environmentObject(self)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        viewController.modalPresentationStyle = .overFullScreen
        self.navigationController.setViewControllers([viewController], animated: false)
    }
    
    func dismissFlow() {
        rootController.dismiss(animated: true)
    }
    
    func showTransferConfirmFlow(tokenTransferModel: CIS2TokenTransferModel) {
        let viewModel: TransferTokenConfirmViewModel = .init(tokenTransferModel: tokenTransferModel, transactionsService: dependencyProvider.transactionsService(), storageManager: dependencyProvider.storageManager())
        let view = TransferTokenConfirmView(viewModel: viewModel, isPresented: false).environmentObject(self)
        let viewController = SceneViewController(content: view)
        self.navigationController.pushViewController(viewController, animated: true)
    }
    
    func transactionSuccessFlow(_ transferDataType: TransferEntity, tokenTransferModel: CIS2TokenTransferModel) {
        let viewModel = TransferTokenSubmittedViewModel(transferDataType: transferDataType, tokenTransferModel: tokenTransferModel)
        let view = TransferTokenSubmittedView().environmentObject(viewModel).environmentObject(self)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        viewController.modalPresentationStyle = .overFullScreen
        
        navigationController.popToRootViewController(animated: false)
        navigationController.present(viewController, animated: true)
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
            onTxSuccess: onTxSuccess,
            onTxReject: onTxReject
        )
        tokenTransferModel.amountTokenSend = .init(BigInt(stringLiteral: data.data.amount), 6)
        tokenTransferModel.recipient = data.data.to
        tokenTransferModel.tokenType = .ccd
        
        let viewModel: TransferTokenConfirmViewModel = .init(tokenTransferModel: tokenTransferModel, transactionsService: dependencyProvider.transactionsService(), storageManager: dependencyProvider.storageManager())
        let view = TransferTokenConfirmView(viewModel: viewModel, isPresented: true).environmentObject(self)
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
        navigationController.pushViewController(vc, animated: true)
    }

    func showRecepientPicker(_ onPicked: @escaping (String) -> Void) {
        let vc = SelectRecipientFactory.create(with: SelectRecipientPresenter(delegate: self, closure: { [weak self] output in
            onPicked(output.address)
            self?.navigationController.popViewController(animated: true)
        },
                                                                              storageManager: dependencyProvider.storageManager(),
                                                                              mode: .addressBook,
                                                                              ownAccount: account))
        navigationController.pushViewController(vc, animated: true)
    }
}

extension TransferTokenRouter: SelectRecipientPresenterDelegate {
    func didSelect(recipient: RecipientDataType) {
        onAddressPicked.send(recipient.address)
    }

    func createRecipient() {
        showAddRecipient()
    }

    func selectRecipientDidSelectQR() {
        showQrAddressPicker { [weak self] address in
            self?.onAddressPicked.send(address)
        }
    }
    
    func showAddRecipient() {
        let vc = AddRecipientFactory.create(with: AddRecipientPresenter(delegate: self, dependencyProvider: dependencyProvider, mode: .add))
        navigationController.pushViewController(vc, animated: true)
    }
}

extension TransferTokenRouter: AddRecipientPresenterDelegate {
    func addRecipientDidSelectSave(recipient: RecipientDataType) {
        onAddressPicked.send(recipient.address)
    }
    
    func addRecipientDidSelectQR() {
        showQrAddressPicker { [weak self] address in
            self?.scanAddressQr(didScanAddress: address)
        }
    }
    
    /// This is reall shi**t need to refactore his, or replace with normal swiftui impl
    func scanAddressQr(didScanAddress address: String) {
        let addRecipientViewController = getAddRecipientViewController(dependencyProvider: dependencyProvider)
        addRecipientViewController.presenter.setAccountAddress(address)
    }
    
    func getAddRecipientViewController(dependencyProvider: WalletAndStorageDependencyProvider) -> AddRecipientViewController {
        let addRecInHierarchy = self.navigationController.viewControllers.last { $0 is AddRecipientViewController }
                as? AddRecipientViewController
        let addRecipientViewController = addRecInHierarchy ?? insertAddRecipientViewController(dependencyProvider: dependencyProvider)
        return addRecipientViewController
    }
    
    private func insertAddRecipientViewController(dependencyProvider: WalletAndStorageDependencyProvider) -> AddRecipientViewController {
        let vc = AddRecipientFactory.create(with: AddRecipientPresenter(delegate: self, dependencyProvider: dependencyProvider, mode: .add))
        var vcs = navigationController.viewControllers
        vcs.insert(vc, at: vcs.count-1)
        navigationController.setViewControllers(vcs, animated: false)
        return vc
    }
}
