//
//  BorderedButton.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 29.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

@IBDesignable
class BorderedButton: BaseButton {

    override func initialize() {
        super.initialize()

        titleLabel?.font = Fonts.buttonTitle
        setTitleColor(UIColor.greyAdditional, for: .normal)
        backgroundColor = .clear
        layer.cornerRadius = 26
        layer.borderWidth = 2
        layer.borderColor = UIColor.greyAdditional.cgColor
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = imageView {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: (bounds.width - 40), bottom: 0, right: 5)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: imageView.frame.width)
        }
    }
}
