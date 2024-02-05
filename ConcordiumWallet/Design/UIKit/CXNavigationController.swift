//
//  CXNavigationController.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 08.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import UIKit

class CXNavigationController: UINavigationController {
    var statusBarStyle = UIStatusBarStyle.lightContent

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        let image = UIImage(named: "backButtonIcon")
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBar.tintColor = .white
        navigationBar.backgroundColor = .clear
//        navigationBar.barTintColor = .clear
        navigationItem.scrollEdgeAppearance = navigationBarAppearance
        navigationItem.standardAppearance = navigationBarAppearance
        navigationItem.compactAppearance = navigationBarAppearance
        setNeedsStatusBarAppearanceUpdate()
        
        navigationBar.backIndicatorImage = image
        navigationBar.backIndicatorTransitionMaskImage = image
        
        let BarButtonItemAppearance = UIBarButtonItem.appearance()
        BarButtonItemAppearance.setTitleTextAttributes([.foregroundColor: UIColor.clear], for: .normal)
        
    }
}
