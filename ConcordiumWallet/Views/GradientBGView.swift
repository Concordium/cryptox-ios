//
//  GradientBGView.swift
//  ConcordiumWallet
//
//  Created by Alex Kudlak on 2021-08-03.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

class GradientBGView: UIView {
    override open class var layerClass: AnyClass {
       return CAGradientLayer.classForCoder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        let myLayer = CALayer()
        let myImage = UIImage(named: "new_bg")?.cgImage
        myLayer.frame = UIScreen.main.bounds
        myLayer.contents = myImage
        layer.insertSublayer(myLayer, at: 0)
    }
}
