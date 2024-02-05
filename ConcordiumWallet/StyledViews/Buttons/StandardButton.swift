//
//  StandardButton.swift
//  ConcordiumWallet
//
//  Created by Concordium on 11/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit

@IBDesignable
class StandardButton: BaseButton {

    override func initialize() {
        super.initialize()

        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        setTitleColor(UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1), for: .normal)
        setTitleColor(UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 0.7), for: .disabled)
        setBackgroundColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        setBackgroundColor(UIColor.white, for: .normal)
        
        tintColor = UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height/2
    }
}


@IBDesignable
class BorderButonButton: BaseButton {

    override func initialize() {
        super.initialize()

        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        setTitleColor(UIColor.white, for: .normal)
        setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .disabled)
        setBackgroundColor(UIColor.clear, for: .disabled)
        setBackgroundColor(UIColor.clear, for: .normal)
        
        tintColor = .white
        
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height/2
    }
}
