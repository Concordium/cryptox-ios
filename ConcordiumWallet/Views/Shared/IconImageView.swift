//
//  IconImageView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 08.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class IconImageView: UIImageView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        isOpaque = true
        layer.cornerRadius = 21
        
        backgroundColor = .clear
    }
}
