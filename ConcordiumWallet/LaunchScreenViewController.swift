//
//  LaunchScreenViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 27.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class LaunchScreenFactory {
    class func create() -> LaunchScreenViewController {
        LaunchScreenViewController.instantiate(fromStoryboard: "LaunchScreen") { coder in
            return LaunchScreenViewController(coder: coder)
        }
    }
}


class LaunchScreenViewController: UIViewController, Storyboarded {}
