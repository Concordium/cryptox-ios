//
//  OperationRoundedView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 26.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class OperationRoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.borderWidth = 2.0
        layer.cornerRadius = 26.0
        layer.borderColor = UIColor.greyAdditional.cgColor
    }
}
