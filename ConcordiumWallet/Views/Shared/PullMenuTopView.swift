//
//  PullMenuRoundedView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 26.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class PullMenuTopView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .clear
        
        if let view = subviews.filter({ $0.tag == 1 }).first {
            view.layer.cornerRadius = 2.0
        }
    }
}


class PullMenuView: UIStackView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 26
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        backgroundColor = UIColor.blackSecondary
    }
}
