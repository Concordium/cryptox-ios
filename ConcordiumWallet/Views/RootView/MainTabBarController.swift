//
//  MainTabBarController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Combine

class MainTabBarController: BaseTabBarController {
    let accountsCoordinator: AccountsCoordinator
    let collectionsCoordinator: CollectionsCoordinator
    let moreCoordinator: MoreCoordinator
    let accountsMainRouter: AccountsMainRouter
    
    private var cancellables: [AnyCancellable] = []
    let defaultProvider = ServicesProvider.defaultProvider()

    init(accountsCoordinator: AccountsCoordinator,
         collectionsCoordinator: CollectionsCoordinator,
         moreCoordinator: MoreCoordinator,
         accountsMainRouter: AccountsMainRouter
    ) {
        self.accountsCoordinator = accountsCoordinator
        self.collectionsCoordinator = collectionsCoordinator
        self.moreCoordinator = moreCoordinator
        self.accountsMainRouter = accountsMainRouter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionsCoordinator.start()
        moreCoordinator.start()
        let newsFeedController = SceneViewController(content: NewsFeed())
        newsFeedController.tabBarItem = UITabBarItem(title: "news_tab_title".localized, image: UIImage(named: "tab_item_news"), tag: 5)
        newsFeedController.extendedLayoutIncludesOpaqueBars = false
        viewControllers = [accountsMainRouter.rootScene(), newsFeedController, collectionsCoordinator.navigationController, moreCoordinator.navigationController]
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}

extension MainTabBarController: AccountsCoordinatorDelegate {
    func showScanAddressQR() {
        selectedViewController = accountsCoordinator.navigationController
        accountsCoordinator.showScanAddressQR()
    }
    
    func createNewAccount() {
        selectedViewController = accountsCoordinator.navigationController
        accountsCoordinator.showCreateNewAccount()
    }

    func showIdentities() {}
    func createNewIdentity() {}
    func noIdentitiesFound() {}
    func showCreateNewIdentity() {}
}

extension MainTabBarController: IdentitiesCoordinatorDelegate {
    func finishedDisplayingIdentities() {
        
    }
}

extension MainTabBarController: BackupAlertControllerDelegate {
    func didApplyBackupOk() {
        accountsCoordinator.showExport()
    }
}

extension MainTabBarController: NotificationNavigationDelegate {
    func openTransactionFromNotification(with userInfo: [AnyHashable : Any]) {
        guard let accountAddress = userInfo["recipient"] as? String,
              let account = defaultProvider.storageManager().getAccount(withAddress: accountAddress),
              let selectedNavigationController = selectedViewController as? UINavigationController
        else { return }

        let accountDetailRouter = AccountDetailsCoordinator(navigationController: selectedNavigationController,
                                                            dependencyProvider: defaultProvider,
                                                            parentCoordinator: accountsCoordinator,
                                                            account: account)
        guard let transactionId = userInfo["reference"] as? String
        else { return }
        let notificationType = userInfo["type"] as? String
        
        if notificationType == TransactionNotificationTypes.ccd.rawValue {
            TransactionNotificationService().handleCCDTransaction(account: account, transactionId: transactionId, accountDetailRouter: accountDetailRouter) {
                accountDetailRouter.showTransactionDetail(viewModel: $0)
            }
        } else {
            let detailRouter = AccountDetailRouter(account: account, navigationController: selectedNavigationController, dependencyProvider: defaultProvider)
            Task {
                if let token = await TransactionNotificationService().tokenObject(from: userInfo) {
                        detailRouter.showCIS2TokenDetailsFlow(token, account: account)
                }
            }
        }
    }
}
