//
//  RoundedCurrencyView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//


import UIKit

@IBDesignable
class RoundedCurrencyView: BaseView {

    override func initialize() {
        super.initialize()
        layer.cornerRadius = 7
        layer.backgroundColor = UIColor.greyMain.cgColor
    }
}
