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
    func showAccountDetailFlow(for account: AccountDataType)
    func showTx(_ tx: TransactionViewModel)
    func showEarnFlow(_ account: AccountDataType)
}

protocol CIS2TokenDetailRoutable: AnyObject {
    func showAccountAddressQR(_ account: AccountDataType)
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
    func showAccountDetailFlow(for account: AccountDataType) {
        let accountDetailCoordinator = AccountDetailsCoordinator.init(
            navigationController: navigationController,
            dependencyProvider: dependencyProvider,
            parentCoordinator: self,
            account: account)
        
        accountDetailCoordinator.accountsMainViewDelegate = accountMainViewDelegate
        accountDetailCoordinator.showLegacyAccountDetails(account: account)
    }
    
    @MainActor
    func showEarnFlow(_ account: AccountDataType) {
        let accountDetailCoordinator = AccountDetailsCoordinator.init(
            navigationController: navigationController,
            dependencyProvider: dependencyProvider,
            parentCoordinator: self,
            account: account)
        
        accountDetailCoordinator.accountsMainViewDelegate = accountMainViewDelegate
        accountDetailCoordinator.start(entryPoint: .earn)
    }
    
    @MainActor
    func showAccountSettings(_ account: AccountDataType) {
        let accountDetailCoordinator = AccountDetailsCoordinator.init(
            navigationController: navigationController,
            dependencyProvider: dependencyProvider,
            parentCoordinator: self,
            account: account)
        
        accountDetailCoordinator.accountsMainViewDelegate = accountMainViewDelegate
        accountDetailCoordinator.start(entryPoint: .settings)
    }

    func showTx(_ tx: TransactionViewModel) {
//        let vc = TransactionDetailFactory.create(with: TransactionDetailPresenter(delegate: self, viewModel: tx))
//        navigationController.pushViewController(vc, animated: true)
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
}

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

