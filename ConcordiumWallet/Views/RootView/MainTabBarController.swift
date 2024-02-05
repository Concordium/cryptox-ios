//
//  MainTabBarController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit

class MainTabBarController: BaseTabBarController {

    let accountsCoordinator: AccountsCoordinator
    let collectionsCoordinator: CollectionsCoordinator
//    let identitiesCoordinator: IdentitiesCoordinator
    let moreCoordinator: MoreCoordinator
    
    let accountsMainRouter: AccountsMainRouter

    deinit { print("[deallocated] -- \(String(describing: self))") }

    init(accountsCoordinator: AccountsCoordinator,
         collectionsCoordinator: CollectionsCoordinator,
//         identitiesCoordinator: IdentitiesCoordinator,
         moreCoordinator: MoreCoordinator,
         accountsMainRouter: AccountsMainRouter
    ) {
        self.accountsCoordinator = accountsCoordinator
        self.collectionsCoordinator = collectionsCoordinator
//        self.identitiesCoordinator = identitiesCoordinator
        self.moreCoordinator = moreCoordinator
        self.accountsMainRouter = accountsMainRouter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        accountsCoordinator.delegate = self
//        accountsCoordinator.start()
        collectionsCoordinator.start()
//        identitiesCoordinator.delegate = self
//        identitiesCoordinator.start()
        moreCoordinator.start()
        viewControllers = [accountsMainRouter.rootScene(), collectionsCoordinator.navigationController, moreCoordinator.navigationController]
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setup() {
        
        guard ConsentManager.shared.delegate == nil  else { return }
        
        if ConsentManager.shared.isAnalyticsStart  == false {
            ConsentManager.shared.delegate = self
            ConsentManager.shared.process()
        }
    }
}

extension MainTabBarController: AccountsCoordinatorDelegate {
    func showScanAddressQR() {
        selectedViewController = accountsCoordinator.navigationController
        accountsCoordinator.showScanAddressQR()
    }
    
#warning("Max, fix me pls")

    func showIdentities() {
//        let identitiesCoordinator = IdentitiesCoordinator(navigationController: navigationController,
//                                                          dependencyProvider: dependencyProvider,
//                                                          parentCoordinator: self)
//        self.childCoordinators.append(identitiesCoordinator)
//        identitiesCoordinator.showInitial(animated: true)
    }
    
    func createNewAccount() {
        selectedViewController = accountsCoordinator.navigationController
        accountsCoordinator.showCreateNewAccount()
    }

    func createNewIdentity() {
//        selectedViewController = identitiesCoordinator.navigationController
//        identitiesCoordinator.showCreateNewIdentity()
    }
    
    func noIdentitiesFound() {
//        identitiesCoordinator.delegate?.noIdentitiesFound()
    }
    
    func showCreateNewIdentity() {
//        selectedViewController = identitiesCoordinator.navigationController
//        identitiesCoordinator.showCreateNewIdentity()
    }
    
//    func showAccountFinalizedNotification(_ notification: FinalizedAccountsNotification) {
//        let vc = BackupAlertFactory.create(delegate: self)
//        vc.modalPresentationStyle = .overCurrentContext
//        present(vc, animated: false, completion: nil)
//    }
}


extension MainTabBarController: IdentitiesCoordinatorDelegate {
    func finishedDisplayingIdentities() {
        
    }
}

extension MainTabBarController: BackupAlertControllerDelegate {
 
    func didApplyBackupOk() {
        accountsCoordinator.showExport()
        //selectedViewController = moreCoordinator.navigationController
        //moreCoordinator.showExport()
    }
}


extension MainTabBarController: ConsentManagerDelegate {
    
    func willPresentGDPRAlert() {
        DispatchQueue.main.async { [weak self] in
            let controller = AnalyticsPermissionController()
            controller.modalPresentationStyle = .fullScreen
            self?.present(controller, animated: true, completion: nil)
        }
    }
}
