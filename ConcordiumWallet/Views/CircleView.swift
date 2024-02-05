//
//  CircleView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 15.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class CircleView: UIView {
    
    override func layoutSubviews() {
        layer.cornerRadius = frame.size.height / 2.0
        super.layoutSubviews()
    }
}
