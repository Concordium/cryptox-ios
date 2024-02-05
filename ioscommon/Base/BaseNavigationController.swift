//
//  BaseNavigationController.swift
//  Foundation
//
//  Created by Valentyn Kovalsky on 22/08/2018.
//  Copyright © 2018 Springfeed. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    var statusBarStyle = UIStatusBarStyle.lightContent

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
//        setupBaseNavigationControllerStyle()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
}



extension BaseNavigationController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        
        guard viewController.navigationItem.leftBarButtonItem == nil else {
            return
        }
        
        if viewControllers.first == viewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else if viewController is BiometricsEnablingViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else {
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "backButtonIcon"), style: .plain, target: self, action:  #selector(self.backButtonTapped))
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
//        navigationController.interactivePopGestureRecognizer?.delegate = viewController
        
       if viewController is BiometricsEnablingViewController {
            viewController.navigationItem.leftBarButtonItem = nil
            viewController.navigationItem.backBarButtonItem = nil
        } else {
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}


extension BaseNavigationController {

    @objc func backButtonTapped() {
        self.popViewController(animated: true)
    }
}



//extension UINavigationController {
//    func setupBaseNavigationControllerStyle() {
//        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.text,
//                                                                  NSAttributedString.Key.font: Fonts.navigationBarTitle]
//        navigationBar.tintColor = UIColor.greySecondary
//        navigationBar.isTranslucent = false
//        navigationBar.shadowImage = UIImage()
//
//        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        navigationBar.shadowImage = UIImage()
//        navigationBar.isTranslucent = true
//        view.backgroundColor = UIColor.clear
//
//        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
//        navigationBar.titleTextAttributes = textAttributes
//
//        let navigationBarAppearace = UINavigationBar.appearance()
//        let image = UIImage(named: "backButtonIcon")
//        navigationBarAppearace.backIndicatorImage = image
//        navigationBarAppearace.backIndicatorTransitionMaskImage = image
//    }
//}
