//
//  CollectionsCoordinator.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class CollectionsCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController


    private var dependencyProvider: NFTFlowCoordinatorDependencyProvider

    deinit { print("[deallocated] -- \(String(describing: self))") }
    
    init(navigationController: UINavigationController, dependencyProvider: NFTFlowCoordinatorDependencyProvider) {
        self.navigationController = navigationController
        self.dependencyProvider = dependencyProvider
    }

    func start() {
        let vc = NFTProvidersFactory.create(with: NFTProvidersPresenter(dependencyProvider: dependencyProvider, delegate: self), mode: .marketplace)
        vc.tabBarItem = UITabBarItem(title: "collections_tab_title".localized, image: UIImage(named: "tab_tokens_icon"), tag: 0)
        navigationController.pushViewController(vc, animated: false)
    }
}



// Add Provider
extension CollectionsCoordinator: NFTProvidersPresenterDelegate {
    
    func search() { }
    
    func addProvider() {
        //let vc = NFTProvidersFactory.create(with: NFTProvidersPresenter(dependencyProvider: dependencyProvider, delegate: self))
        let vc = NFTImportFactory.create(with: NFTImportPresenter(dependencyProvider: dependencyProvider, delegate: self))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func open(mode: NFTProviders.Mode) {
        let vc = NFTProvidersFactory.create(with: NFTProvidersPresenter(dependencyProvider: dependencyProvider, delegate: self), mode: mode)
        vc.tabBarItem = UITabBarItem(title: "collections_tab_title".localized, image: UIImage(named: "tab_tokens_icon"), tag: 0)
        navigationController.pushViewController(vc, animated: false)
    }
    
    func pop() {
        navigationController.popViewController(animated: true)
    }
}

// Add Provider
extension CollectionsCoordinator: NFTImportPresenterDelegate {
    
    func dissmiss() {
        navigationController.popViewController(animated: true)
    }
    
    func marketplaceWasAded() {
        
        for controller in navigationController.viewControllers {
            guard let controller = controller as? ActionProtocol  else { continue }
            controller.didInitiate(action: NFTProviders.Action.fetch(forceReload: true))
            break
        }
    }
}
