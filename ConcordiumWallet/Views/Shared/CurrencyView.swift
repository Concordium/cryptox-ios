//
//  CurrencyView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 26.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class CurremcyView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        isOpaque = true
        layer.cornerRadius = 7
        
        layer.backgroundColor = UIColor.greyMain.withAlphaComponent(0.4).cgColor
    }
}
