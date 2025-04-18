//
//  CreateIdentityCoordinator.swift
//  ConcordiumWallet
//
//  Created by Concordium on 14/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import SwiftUI

protocol AccountDetailsDelegate: AnyObject {
    func accountDetailsClosed()
    func retryCreateAccount(failedAccount: AccountDataType)
    func accountRemoved()
}

enum AccountDetailsFlowEntryPoint {
    case receive
    case settings
}

@MainActor
class AccountDetailsCoordinator: Coordinator,
                                 RequestPasswordDelegate
{
    var childCoordinators = [Coordinator]()
    weak var parentCoordinator: AccountDetailsDelegate?
    weak var accountsMainViewDelegate: AccountsMainViewDelegate?

    var navigationController: UINavigationController

    private var dependencyProvider: AccountsFlowCoordinatorDependencyProvider & StakeCoordinatorDependencyProvider
    private var account: AccountDataType

    private var accountDetailsPresenter: AccountDetailsPresenter?
    
    init(navigationController: UINavigationController,
         dependencyProvider: AccountsFlowCoordinatorDependencyProvider & StakeCoordinatorDependencyProvider,
         parentCoordinator: AccountDetailsDelegate,
         account: AccountDataType) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
        self.dependencyProvider = dependencyProvider
        self.account = account
        self.navigationController.modalPresentationStyle = .fullScreen
        
    }
    deinit {
        childCoordinators.removeAll()
    }
    func start() {
        start(entryPoint: .settings)
    }
    
    func start(entryPoint: AccountDetailsFlowEntryPoint) {
        switch entryPoint {
        case .receive:
                showAccountAddressQR(account)
        case .settings:
            showSettings()
        }
    }
    
    func showSettings() {
        let presenter = AccountSettingsPresenter(account: account, delegate: self)
        navigationController.pushViewController(presenter.present(AccountSettingsView.self), animated: true)
    }

    func pressedDismiss() {
        navigationController.dismiss(animated: false)
    }

    func showAccountAddressQR(_ account: AccountDataType) {
        let accountAddressQRCoordinator = AccountAddressQRCoordinator(navigationController: CXNavigationController(),
                                                                      delegate: self,
                                                                      account: account)
        accountAddressQRCoordinator.start()
        navigationController.present(accountAddressQRCoordinator.navigationController, animated: true)
        self.childCoordinators.append(accountAddressQRCoordinator)
    }

    func showReleaseSchedule(account: AccountDataType) {
        let vc = ReleaseScheduleDataFactory.create(with: ReleaseSchedulePresenter(delegate: self, account: account))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showTransferFilters(account: AccountDataType) {
        let vc = TransferFiltersFactory.create(with: TransferFiltersPresenter(delegate: self, account: account))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showExportPrivateKey(account: AccountDataType) {
        let presenter = ExportPrivateKeyPresenter(account: account, delegate: self)
        
        navigationController.pushViewController(presenter.present(ExportPrivateKeyView.self), animated: true)
    }
    
    func showExportTransactionLog(account: AccountDataType) {
        let presenter = ExportTransactionLogPresenter(account: account, delegate: self)
        navigationController.pushViewController(presenter.present(ExportTransactionLogView.self), animated: true)
    }
    
    func renameAccount(account: AccountDataType) {
        let alert = UIAlertController(title: "renameaccount.title".localized, message: "renameaccount.message".localized, preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = account.displayName
        }

        let saveAction = UIAlertAction(title: "renameaccount.save".localized, style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields![0], let newName = textField.text, !newName.isEmpty {
                do {
                    try account.write {
                        var mutableAccount = $0
                        mutableAccount.name = newName
                    }.get()
                    if let recipient = self.dependencyProvider.storageManager().getRecipient(withAddress: account.address) {
                        let newRecipient = RecipientEntity(name: newName, address: account.address)
                        try self.dependencyProvider.storageManager().editRecipient(oldRecipient: recipient, newRecipient: newRecipient)
                    }
                    self.navigationController.viewControllers.last?.showToast(title: "Name changed", imageName: "ico_successfully")
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
        })

        let cancelAction = UIAlertAction(title: "renameaccount.cancel".localized, style: .cancel, handler: nil)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        navigationController.present(alert, animated: true, completion: nil)
    }
}

extension AccountDetailsCoordinator: ShowShieldedDelegate {
    func onboardingCarouselClosed() {
        navigationController.popViewController(animated: true)
    }

    func onboardingCarouselSkiped() {
        self.navigationController.popViewController(animated: false)
        accountDetailsPresenter?.viewDidLoad()
        self.navigationController.popViewController(animated: true)
    }

    func onboardingCarouselFinished() {
        self.navigationController.popViewController(animated: false)
        accountDetailsPresenter?.viewDidLoad()
        self.navigationController.popViewController(animated: true)
    }
}

extension AccountDetailsCoordinator: ReleaseSchedulePresenterDelegate {
    
}

extension AccountDetailsCoordinator: TransferFiltersPresenterDelegate {
    func refreshTransactionList() {
        accountDetailsPresenter?.setShouldRefresh(true)
    }
}

extension AccountDetailsCoordinator: AccountAddressQRCoordinatorDelegate {
    func accountAddressQRCoordinatorFinished() {
        navigationController.dismiss(animated: true)
        self.childCoordinators.removeAll {$0 is AccountAddressQRCoordinator}
    }
}

extension AccountDetailsCoordinator: AccountSettingsPresenterDelegate {
    func transferFiltersTapped() {
        showTransferFilters(account: account)
    }

    func releaseScheduleTapped() {
        showReleaseSchedule(account: account)
    }
    
    func exportPrivateKeyTapped() {
        showExportPrivateKey(account: account)
    }
    
    func exportTransactionLogTapped() {
        showExportTransactionLog(account: account)
    }
    
    func renameAccountTapped() {
        renameAccount(account: account)
    }
}

extension AccountDetailsCoordinator: ExportPrivateKeyPresenterDelegate {
    func finishedExportingPrivateKey() {
        navigationController.popViewController(animated: true)
    }
    
    func shareExportedFile(url: URL, completion: @escaping (Bool) -> Void) {
        share(items: [url], from: navigationController, completion: completion)
    }
}

extension AccountDetailsCoordinator: ExportTransactionLogPresenterDelegate {
    func saveTapped(url: URL, completion: @escaping (Bool) -> Void) {
        share(items: [url], from: navigationController, completion: completion)
    }
    
    func doneTapped() {
        navigationController.popViewController(animated: true)
    }
}

extension AccountDetailsCoordinator {
    public func showAccountSettings() {
        let presenter = AccountSettingsPresenter(account: account, delegate: self)
        navigationController.pushViewController(
            SceneViewController(content: AccountSettingsView(viewModel: .init(account: account))),
            animated: true
        )
    }
}
