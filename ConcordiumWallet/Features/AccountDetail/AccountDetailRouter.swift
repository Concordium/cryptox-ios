//
//  AccountDetailNavigationProxy.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 07.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import UIKit
import Combine

protocol AccountDetailRoutable: AnyObject {
    func showImportTokenFlow(for account: AccountDataType)
    func showAccountDetailFlow(for account: AccountDataType)
    func showCIS2TokenDetailsFlow(_ token: CIS2Token, account: AccountDataType)
    func showTx(_ tx: TransactionViewModel)
}

protocol CIS2TokenDetailRoutable: AnyObject {
    func showAccountAddressQR(_ account: AccountDataType)
    func showSendTokenFlow(tokenType: CXTokenType)
}

final class AccountDetailRouter: ObservableObject {
    let navigationController: UINavigationController
    let dependencyProvider: ServicesProvider
    let account: AccountDataType
    weak var accountMainViewDelegate: AccountsMainViewDelegate?
        
    init(account: AccountDataType, navigationController: UINavigationController, dependencyProvider: ServicesProvider) {
        self.navigationController = navigationController
        self.dependencyProvider = dependencyProvider
        self.account = account
    }
    
    
}


extension AccountDetailRouter: TransactionDetailPresenterDelegate {}
extension AccountDetailRouter: AccountDetailRoutable {
    @MainActor
    func showImportTokenFlow(for account: AccountDataType) {
        let view = ImportTokenView(viewModel: .init(storageManager: self.dependencyProvider.storageManager(),
                                                    networkManager: self.dependencyProvider.networkManager(),
                                                    account: account),
                                   searchTokenViewModel: SearchTokenViewModel(cis2Service:
                                                                                CIS2Service(networkManager: self.dependencyProvider.networkManager(),
                                                                                            storageManager: self.dependencyProvider.storageManager())))
        let vc = SceneViewController(content: view)
        navigationController.present(vc, animated: true)
    }

    @MainActor
    func showAccountDetailFlow(for account: AccountDataType) {
        let accountDetailCoordinator = AccountDetailsCoordinator.init(
            navigationController: navigationController,
            dependencyProvider: dependencyProvider,
            parentCoordinator: self,
            account: account)
        
        accountDetailCoordinator.accountsMainViewDelegate = accountMainViewDelegate
        accountDetailCoordinator.showLegacyAccountDetails(account: account)
    }
    
    func showCIS2TokenDetailsFlow(_ token: CIS2Token, account: AccountDataType) {
        let viewModel = CIS2TokenDetailViewModel(
            token,
            account: account,
            storageManager: dependencyProvider.storageManager(),
            networkManager: dependencyProvider.networkManager(),
            onDismiss: { [weak navigationController] in
                navigationController?.popViewController(animated: true)
            })
        let view = CIS2TokenDetailView(viewModel: viewModel).environmentObject(self)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
    func showTx(_ tx: TransactionViewModel) {
        let vc = TransactionDetailFactory.create(with: TransactionDetailPresenter(delegate: self, viewModel: tx))
        navigationController.pushViewController(vc, animated: true)
    }
}


extension AccountDetailRouter: AccountAddressQRCoordinatorDelegate {
    func accountAddressQRCoordinatorFinished() {
        
    }
}

extension AccountDetailRouter :CIS2TokenDetailRoutable {
    func showAccountAddressQR(_ account: AccountDataType) {
        let accountAddressQRCoordinator = AccountAddressQRCoordinator(navigationController: CXNavigationController(),
                                                                      delegate: self,
                                                                      account: account)
        accountAddressQRCoordinator.start()
        navigationController.present(accountAddressQRCoordinator.navigationController, animated: true)
    }
    
    func showSendTokenFlow(tokenType: CXTokenType) {
        let router = TransferTokenRouter(root: navigationController, account: account, dependencyProvider: dependencyProvider)
        router.showSendTokenFlow(tokenType: tokenType)
    }
}

//
//extension AccountDetailRouter: AccountDetailNavigationProxy {
//    func showAccountAddressQR(_ account: AccountDataType) {
//
//    }
//
//    func showAccountSettings() {
//
//    }
//
//    func showRecepientPicker(_ onPicked: @escaping (String) -> Void) {
//        let vc = SelectRecipientFactory.create(with: SelectRecipientPresenter(closure: { [weak self] output in
//            onPicked(output.address)
//            self?.navigationController.popViewController(animated: true)
//        },
//                                                                              storageManager: dependencyProvider.storageManager(),
//                                                                              mode: .addressBook,
//                                                                              ownAccount: account))
//        navigationController.pushViewController(vc, animated: true)
//    }
//
//    func showQrAddressPicker(_ onPicked: @escaping (String) -> Void) {
//        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), closure: { [weak self] output in
//            onPicked(output.address)
//            self?.navigationController.popViewController(animated: true)
//        }))
//        navigationController.pushViewController(vc, animated: true)
//    }
//
//    func showSendTokenFlow(tokenType: CXTokenType) {
//        let router = TransferTokenRouter(root: navigationController, account: account, dependencyProvider: dependencyProvider)
//        router.showSendTokenFlow(tokenType: tokenType)
//    }
//
//    func showCIS2TokenDetailsFlow(_ token: CIS2Token, account: AccountDataType) {
//        let viewModel = CIS2TokenDetailViewModel(
//            token,
//            account: account,
//            proxy: self,
//            storageManager: dependencyProvider.storageManager(),
//            onPop: { [weak navigationController] in
//                navigationController?.popViewController(animated: true)
//            })
//        let view = CIS2TokenDetailView(viewModel: viewModel)
//        let viewController = SceneViewController(content: view)
//        viewController.hidesBottomBarWhenPushed = true
//        navigationController.pushViewController(viewController, animated: true)
//    }
//
//    func showAccountDetailFlow(for account: AccountDataType) {
////        self.showOldAccountDetails(account: account)
//    }
//
//    @MainActor
//    func showImportTokenFlow(for account: AccountDataType) {
////        self.showImportTokenFlow(account.address)
//    }
//
//    func showTx(_ tx: TransactionViewModel) {
////        showTransactionDetail(viewModel: tx)
//    }
//}
//
//extension AccountDetailRouter {
//    @MainActor
//    func showOldAccountDetails(account: AccountDataType)  {
////        let accountDetailsPresenter = AccountDetailsPresenter(dependencyProvider: dependencyProvider,
////                                                          account: account,
////                                                          delegate: self)
////        let vc = AccountDetailsFactory.create(with: accountDetailsPresenter)
//////        vc.hidesBottomBarWhenPushed = true
////        navigationController.pushViewController(vc, animated: true)
//        AccountDetailsCoordinator.init(
//            navigationController: navigationController,
//            dependencyProvider: dependencyProvider,
//            parentCoordinator: self,
//            account: account).showAccountDetails(account: account)
//    }
//}
//
//extension AccountDetailRouter: RequestPasswordDelegate {
//    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
//        DummyRequestPasswordDelegate().requestUserPassword(keychain: keychain)
//    }
//}
//
//extension AccountDetailRouter: AccountDetailsDelegate {
//    func accountDetailsClosed() {
////        navigationController.dismiss(animated: true, completion: nil)
////        if let lastOccurenceIndex = childCoordinators.lastIndex(where: { $0 is AccountDetailsCoordinator }) {
////            childCoordinators.remove(at: lastOccurenceIndex)
////        }
//    }
//
//    func retryCreateAccount(failedAccount: AccountDataType) {
////        navigationController.popViewController(animated: true)
////        showCreateNewAccount(withDefaultValuesFrom: failedAccount)
//    }
//
//    func accountRemoved() {
////        navigationController.popViewController(animated: true)
//    }
//}

extension AccountDetailRouter: AccountDetailsDelegate {
    func accountDetailsClosed() {
        
    }
    
    func retryCreateAccount(failedAccount: AccountDataType) {
        
    }
    
    func accountRemoved() {
        
    }
    
    
}

extension AccountDetailRouter: RequestPasswordDelegate {
    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
        DummyRequestPasswordDelegate().requestUserPassword(keychain: keychain)
    }
}

