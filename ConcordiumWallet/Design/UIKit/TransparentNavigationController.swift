//
//  TransparentNavigationController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 19/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//
import UIKit

class TransparentNavigationController: BaseNavigationController {
    override func viewDidLoad() {
        setupTransparentNavigationControllerStyle()
        view.backgroundColor = .clear
        statusBarStyle = .lightContent
        
//        let navigationBarAppearace = UINavigationBar.appearance()
//        let image = UIImage(named: "backButtonIcon")
//        navigationBarAppearace.backIndicatorImage = image
//        navigationBarAppearace.backIndicatorTransitionMaskImage = image
    }

}

extension UINavigationController {
    func setupTransparentNavigationControllerStyle() {
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "backButtonIcon")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "backButtonIcon")
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: Fonts.navigationBarTitle
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }
}
