//
//  MainTabBarController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Combine
import SwiftUI

protocol ConfigureAccountAlertDelegate: AnyObject {
    func showConfigureAccountAlert()
}

class MainTabBarController: BaseTabBarController {
    let accountsCoordinator: AccountsCoordinator
    let moreCoordinator: MoreCoordinator
    let accountsMainRouter: AccountsMainRouter

    private var cancellables: [AnyCancellable] = []
    let defaultProvider = ServicesProvider.defaultProvider()
    @State private var isAlertVisible: Bool = true
    @State private var isConfigurePopupVisible = true
    var transactionNotificationService = TransactionNotificationService()

    init(accountsCoordinator: AccountsCoordinator,
         moreCoordinator: MoreCoordinator,
         accountsMainRouter: AccountsMainRouter
    ) {
        self.accountsCoordinator = accountsCoordinator
        self.moreCoordinator = moreCoordinator
        self.accountsMainRouter = accountsMainRouter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.backgroundColor = .blackMain
        self.delegate = self
        accountsMainRouter.configureAccountAlertDelegate = self
        moreCoordinator.configureAccountAlertDelegate = self
        moreCoordinator.start()
        let newsFeedController = SceneViewController(content: NewsFeed())
        newsFeedController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_item_news"),
            tag: 5
        )
        newsFeedController.tabBarItem.selectedImage = UIImage(named: "tab_item_news_selected")?.withRenderingMode(.alwaysOriginal)
        newsFeedController.extendedLayoutIncludesOpaqueBars = false
        viewControllers = [accountsMainRouter.rootScene(), newsFeedController, moreCoordinator.navigationController]
        hideKeyboardWhenTappedAround()
        transactionNotificationService.delegate = self
        NotificationCenter.default.addObserver(forName: .hideTabBar, object: nil, queue: .main) { [weak self] notification in
            if let isHidden = notification.userInfo?["isHidden"] as? Bool, let self {
                self.tabBar.isHidden = isHidden
                self.additionalSafeAreaInsets.bottom = isHidden ? -self.tabBar.frame.height : 0

            }
        }
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

extension MainTabBarController: ConfigureAccountAlertDelegate {
    func showConfigureAccountAlert() {
        guard let selectedNavigationController = selectedViewController as? UINavigationController else { return }
        let view = CompleteSetupPopup(isVisible: Binding(
            get: { self.isConfigurePopupVisible },
            set: { self.isConfigurePopupVisible = $0
                if !$0 {
                    selectedNavigationController.popToRootViewController(animated: true)
                    selectedNavigationController.dismiss(animated: true) {
                        DispatchQueue.main.async {
                            self.selectedIndex = 0
                        }
                    }
                }
            }
        ))
        
        let alertViewController = UIHostingController(rootView: view)
        alertViewController.modalPresentationStyle = .overCurrentContext
        alertViewController.view.backgroundColor = .clear
        DispatchQueue.main.async {
            selectedNavigationController.present(alertViewController, animated: false, completion: nil)
        }
    }
}

extension MainTabBarController: NotificationNavigationDelegate, TransactionNotificationServiceDelegate {
    func openTransactionFromNotification(with userInfo: [AnyHashable: Any]) {
        guard
            let accountAddress = userInfo["recipient"] as? String,
            let account = defaultProvider.storageManager().getAccount(withAddress: accountAddress),
            let transactionId = userInfo["reference"] as? String
        else { return }

        let notificationType = userInfo["type"] as? String

        if notificationType == TransactionNotificationTypes.ccd.rawValue {
            transactionNotificationService.handleCCDTransaction(account: account, transactionId: transactionId) { viewModel in
                self.accountsMainRouter.showTransactionDetailFromNotifications(for: account, tx: TransactionDetailViewModel(transaction: viewModel))
            }
        } else {
            transactionNotificationService.handleCIS2Notification(userInfo: userInfo) { token, balance in
                DispatchQueue.main.async {
                    self.accountsMainRouter.showCIS2TokenDetailsFromNotification(for: account, token: AccountDetailAccount.token(token: token, amount: balance?.balance ?? "0.00"))
                }
            }
        }
    }

    func presentTokenAlert(userInfo: [AnyHashable: Any], completion: @escaping (CIS2Token, CIS2TokenBalance?) -> Void) {
        let alertView = NewTokenNotificationPopup(isVisible: Binding(
            get: { self.isAlertVisible },
            set: { self.isAlertVisible = $0
                if !$0 {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        ), userInfo: userInfo) {
            NotificationTokenService().storeNewToken(from: userInfo) { token, balance in
                DispatchQueue.main.async {
                    completion(token, balance)
                }
            }
        }

        let alertViewController = UIHostingController(rootView: alertView)
        alertViewController.modalPresentationStyle = .overCurrentContext
        alertViewController.view.backgroundColor = .clear
        DispatchQueue.main.async {
            self.present(alertViewController, animated: false, completion: nil)
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let selectedIndex = tabBarController.viewControllers?.firstIndex(of: viewController),
           let item = tabBar.items?[selectedIndex],
           item.tag == 0 {
            NotificationCenter.default.post(name: .returnToHomeTabBar, object: nil, userInfo: ["returnToHomeTabBar": true])
        }
    }
}
