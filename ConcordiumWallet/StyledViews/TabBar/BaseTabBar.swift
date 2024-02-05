//
//  BaseTabBar.swift
//  ConcordiumWallet
//
//  Created by Concordium on 14/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit

class BaseTabBarController: UITabBarController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tabBar = UITabBar.appearance()
        tabBar.barTintColor = UIColor.whiteMain
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true

        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor.greySecondary
        
        let appearance = UITabBarItem.appearance()
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12, weight: .medium)]
        appearance.setTitleTextAttributes(attributes, for: .normal)
    }
}
