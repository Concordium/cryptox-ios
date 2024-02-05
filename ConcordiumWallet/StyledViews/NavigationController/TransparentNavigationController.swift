//
//  TransparentNavigationController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 19/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//
import UIKit

class TransparentNavigationController: UINavigationController {

    var statusBarStyle = UIStatusBarStyle.lightContent

    
    override func viewDidLoad() {
        delegate = self
        
//        setupBaseNavigationControllerStyle()
    }
}


extension TransparentNavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        prepareNavigationController(navigationController, viewController: viewController, animated: animated)
    }
    
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        prepareGestureNavigationController(navigationController, viewController: viewController, animated: animated)

    }
}


extension TransparentNavigationController {
    
    func prepareNavigationController(_ navigationController: UINavigationController, viewController: UIViewController, animated: Bool) {
        viewController.title = nil

       
        guard viewController.navigationItem.leftBarButtonItem == nil else {
            return
        }
        
        if viewControllers.first == viewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is GettingStartedViewController || viewController is BiometricsEnablingViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if let vc = viewController as? InitialAccountInfoViewController, let presenter = vc.presenter as? InitialAccountInfoPresenter, presenter.type == .welcomeScreen {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is QRTransactionDataViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is EnterPasswordViewController { } else {
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "backButtonIcon"), style: .plain, target: self, action:  #selector(self.backButtonTapped))
        }
    }
    
    func prepareGestureNavigationController(_ navigationController: UINavigationController, viewController: UIViewController, animated: Bool) {
        viewController.title = nil
        
        navigationController.interactivePopGestureRecognizer?.delegate = viewController

        
        if viewControllers.first == viewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is GettingStartedViewController || viewController is BiometricsEnablingViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if let vc = viewController as? InitialAccountInfoViewController, let presenter = vc.presenter as? InitialAccountInfoPresenter, presenter.type == .welcomeScreen {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is QRTransactionDataViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is EnterPasswordViewController { } else {
            //navigationController.interactivePopGestureRecognizer?.isEnabled = true
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "backButtonIcon"), style: .plain, target: self, action:  #selector(self.backButtonTapped))
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}


extension TransparentNavigationController {

    @objc func backButtonTapped() {
        self.popViewController(animated: true)
    }
}
