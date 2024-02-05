//
//  FilledButton.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 26.08.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

@IBDesignable
class FilledButton: BaseButton {

    override func initialize() {
        super.initialize()

        titleLabel?.font = Fonts.buttonTitle
        setTitleColor(UIColor.blackMain, for: .normal)
        backgroundColor = UIColor.white
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        setBackgroundColor(UIColor.white, for: .disabled)
      
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = imageView {
            imageEdgeInsets = UIEdgeInsets(top: 0, left: (bounds.width - 40), bottom: 0, right: 5)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: imageView.frame.width)
        }
        
        layer.cornerRadius = bounds.height/2
    }
}
