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
        let defaultProvider = ServicesProvider.defaultProvider()
        
        guard let accountAddress = userInfo["recipient"] as? String,
              let account = defaultProvider.storageManager().getAccount(withAddress: accountAddress),
              let navigationController
        else { return }

        let accountDetailRouter = AccountDetailsCoordinator(navigationController: navigationController,
                                                            dependencyProvider: defaultProvider,
                                                            parentCoordinator: accountsCoordinator,
                                                            account: account)
        guard let transactionId = userInfo["reference"] as? String
        else { return }
        
        let transactionLoadingHandler = TransactionsLoadingHandler(account: account, balanceType: .balance, dependencyProvider: defaultProvider)
        
        transactionLoadingHandler.getTransactions()
            .map { transactions in
                return transactions.1.first(where: { $0.details.transactionHash == transactionId })
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error loading transactions: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { transaction in
                if let transaction = transaction {
                    accountDetailRouter.showTransactionDetail(viewModel: transaction)
                } else {
                    print("Transaction not found")
                }
            })
            .store(in: &cancellables)
    }
}
