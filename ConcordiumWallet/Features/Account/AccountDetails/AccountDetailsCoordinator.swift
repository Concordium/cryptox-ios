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
    case details
    case send
    case receive
    case earn
    case settings
}

@MainActor
class AccountDetailsCoordinator: Coordinator,
                                 RequestPasswordDelegate,
                                 EarnPresenterDelegate,
                                 DelegationOnboardingCoordinatorDelegate,
                                 DelegationStatusPresenterDelegate
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
    
    func start() {
        start(entryPoint: .details)
    }
    
    func start(entryPoint: AccountDetailsFlowEntryPoint) {
        switch entryPoint {
        case .details:
            showAccountDetails(account: account)
        case .send:
            showSendFund()
        case .receive:
                showAccountAddressQR(account)
        case .earn:
            showEarn(account: account)
        case .settings:
            showSettings()
        }
    }
    
    func showSettings() {
        let presenter = AccountSettingsPresenter(account: account, delegate: self)
        navigationController.pushViewController(presenter.present(AccountSettingsView.self), animated: true)
    }
    
    func showImportTokenFlow(account: AccountDataType) {
        let view = ImportTokenView(viewModel: .init(storageManager: self.dependencyProvider.storageManager(),
                                                    networkManager: self.dependencyProvider.networkManager(),
                                                    account: account),
                                   searchTokenViewModel: SearchTokenViewModel(cis2Service: CIS2Service(networkManager: self.dependencyProvider.networkManager(),
                                                                                                       storageManager: self.dependencyProvider.storageManager())))
        let vc = SceneViewController(content: view)
        navigationController.present(vc, animated: true)
    }
    
    func showOldAccountDetails(account: AccountDataType)  {
        accountDetailsPresenter = AccountDetailsPresenter(dependencyProvider: dependencyProvider,
                                                          account: account,
                                                          delegate: self)
        let vc = AccountDetailsFactory.create(with: accountDetailsPresenter!)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showAccountDetails(account: AccountDataType) {
        let router = AccountDetailRouter(account: account, navigationController: navigationController, dependencyProvider: dependencyProvider as! ServicesProvider)
        let viewModel = AccountDetailViewModel(
            router: router,
            account: account,
            storageManager: dependencyProvider.storageManager(),
            dependencyProvider: dependencyProvider
        )
        let view = AccountDetailView(viewModel: viewModel)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showLegacyAccountDetails(account: AccountDataType) {
        accountDetailsPresenter = AccountDetailsPresenter(dependencyProvider: dependencyProvider,
                                                          account: account,
                                                          delegate: self)
        let vc = AccountDetailsFactory.create(with: accountDetailsPresenter!)
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    @MainActor func showEarn(account: AccountDataType) {
        if account.baker == nil && account.delegation == nil {
            let presenter = EarnPresenter(account: account, delegate: self)
            navigationController.pushViewController(presenter.present(EarnView.self), animated: true)
        } else if account.baker != nil {
            let bakingCoordinator = BakingCoordinator(
                navigationController: CXNavigationController(),
                dependencyProvider: dependencyProvider,
                account: account,
                parentCoordinator: self)
            bakingCoordinator.start()
            childCoordinators.append(bakingCoordinator)
            navigationController.present(bakingCoordinator.navigationController, animated: true)
            self.navigationController.popViewController(animated: false)
        } else if account.delegation != nil {
            let coordinator = DelegationCoordinator(navigationController: CXNavigationController(),
                                                              dependencyProvider: dependencyProvider ,
                                                              account: account,
                                                              parentCoordinator: self)
            coordinator.showStatus()
            childCoordinators.append(coordinator)
            navigationController.present(coordinator.navigationController, animated: true, completion: nil)
        }
    }
    
    func baker() {
        let bakingCoordinator = BakingCoordinator(
            navigationController: CXNavigationController(),
            dependencyProvider: dependencyProvider,
            account: account,
            parentCoordinator: self)
        bakingCoordinator.start()
        childCoordinators.append(bakingCoordinator)
        navigationController.present(bakingCoordinator.navigationController, animated: true)
        self.navigationController.popViewController(animated: false)
    }
     
    func delegation() {
        self.navigationController.popViewController(animated: false)
        let onboardingDelegator = DelegationOnboardingCoordinator(navigationController: navigationController,
                                                                  parentCoordinator: self,
                                                                  mode: .register)
        childCoordinators.append(onboardingDelegator)
        onboardingDelegator.start()
    }

    func finished(mode: DelegationOnboardingMode) {
        self.navigationController.popViewController(animated: false)
        let coordinator = DelegationCoordinator(navigationController: CXNavigationController(),
                                                          dependencyProvider: dependencyProvider,
                                                          account: account,
                                                          parentCoordinator: self)
        coordinator.showPoolSelection(dataHandler: DelegationDataHandler(account: account, isRemoving: false))
        childCoordinators.append(coordinator)
        navigationController.present(coordinator.navigationController, animated: true, completion: nil)
    }

    func pressedDismiss() {
        navigationController.dismiss(animated: false)
    }

    func closed() {
        self.navigationController.popViewController(animated: true)
    }
    
    func showSendFund(balanceType: AccountBalanceTypeEnum = .balance) {
        self.accountsMainViewDelegate?.showSendFundsFlow(account)
    }
    
    func showAccountAddressQR(_ account: AccountDataType) {
        let accountAddressQRCoordinator = AccountAddressQRCoordinator(navigationController: CXNavigationController(),
                                                                      delegate: self,
                                                                      account: account)
        accountAddressQRCoordinator.start()
        navigationController.present(accountAddressQRCoordinator.navigationController, animated: true)
        self.childCoordinators.append(accountAddressQRCoordinator)
    }
    
    func showTransactionDetail(viewModel: TransactionViewModel) {
        let vc = TransactionDetailFactory.create(with: TransactionDetailPresenter(delegate: self, viewModel: viewModel))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showReleaseSchedule(account: AccountDataType) {
        let vc = ReleaseScheduleDataFactory.create(with: ReleaseSchedulePresenter(delegate: self, account: account))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showDelegation() {
        let coordinator = DelegationCoordinator(navigationController: CXNavigationController(),
                                                          dependencyProvider: dependencyProvider ,
                                                          account: account,
                                                          parentCoordinator: self)
        coordinator.start()
        childCoordinators.append(coordinator)
        navigationController.present(coordinator.navigationController, animated: true, completion: nil)
    }
    
    func showBaking() {
        let coordinator = BakingCoordinator(
            navigationController: CXNavigationController(),
            dependencyProvider: dependencyProvider,
            account: account,
            parentCoordinator: self)
        
        coordinator.start()
        childCoordinators.append(coordinator)
        navigationController.present(coordinator.navigationController, animated: true)
    }
    
    func pressedStop(cost: GTU, energy: Int) {}
    func pressedRegisterOrUpdate() {}
    func pressedClose() {}

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
                    self.navigationController.viewControllers.last(where: { $0 is AccountDetailsViewController })?.title = newName
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

extension AccountDetailsCoordinator: AccountDetailsPresenterDelegate {
    func accountDetailsPresenterSend(_ accountDetailsPresenter: AccountDetailsPresenter, balanceType: AccountBalanceTypeEnum) {
        showSendFund(balanceType: balanceType)
    }
    
    func accountDetailsPresenterAddress(_ accountDetailsPresenter: AccountDetailsPresenter) {
        showAccountAddressQR(account)
    }

    func showEarn() {
        showEarn(account: account)
    }
    
    func showOnrampFlow() {
        let childView = UIHostingController(rootView: CCDOnrampView(dependencyProvider: dependencyProvider))
        navigationController.present(childView, animated: true)
    }

    func accountDetailsPresenter(_ accountDetailsPresenter: AccountDetailsPresenter, retryFailedAccount account: AccountDataType) {
        var accountCopy = AccountDataTypeFactory.create()
        accountCopy.name = account.name
        dependencyProvider.storageManager().removeAccount(account: account)
        parentCoordinator?.retryCreateAccount(failedAccount: accountCopy)
    }

    func accountDetailsPresenter(_ accountDetailsPresenter: AccountDetailsPresenter, removeFailedAccount account: AccountDataType) {
        dependencyProvider.storageManager().removeAccount(account: account)
        parentCoordinator?.accountRemoved()
    }
    
    func accountDetailsShowBurgerMenu(_ accountDetailsPresenter: AccountDetailsPresenter,
                                      balanceType: AccountBalanceTypeEnum,
                                      showsDecrypt: Bool) {
        let presenter = AccountSettingsPresenter(account: account, delegate: self)
        navigationController.pushViewController(presenter.present(AccountSettingsView.self), animated: true)
    }
    
    func transactionSelected(viewModel: TransactionViewModel) {
        showTransactionDetail(viewModel: viewModel)
    }
    
    func accountDetailsClosed() {
        self.parentCoordinator?.accountDetailsClosed()
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

extension AccountDetailsCoordinator: TransactionDetailPresenterDelegate {
    
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

extension AccountDetailsCoordinator: DelegationCoordinatorDelegate {
    func finished() {
        navigationController.dismiss(animated: true)
        self.childCoordinators.removeAll {$0 is DelegationCoordinator }
        refreshTransactionList()
    }
}

extension AccountDetailsCoordinator: BakingCoordinatorDelegate {
    func finishedBakingCoordinator() {
        navigationController.dismiss(animated: true)
        self.childCoordinators.removeAll { $0 is BakingCoordinator }
        refreshTransactionList()
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

extension AccountDetailsCoordinator {
    func showTransactionDetailsFromNotification(transaction: TransactionViewModel) {
        showTransactionDetail(viewModel: transaction)
    }
}
