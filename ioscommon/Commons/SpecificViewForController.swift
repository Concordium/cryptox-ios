//
//  SpecificViewForController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 15.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//


import UIKit


/// SpecificViewForController
protocol SpecificViewForController {
    associatedtype View: UIView
}


// MARK: extension SpecificViewForController

extension SpecificViewForController where Self: UIViewController {
    var customView: View {
        return self.view as! View
    }
}

