//
//  UIAlertAction+Color.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}
