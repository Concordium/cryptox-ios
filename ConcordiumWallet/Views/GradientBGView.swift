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
//        let gradient = CAGradientLayer()
//        gradient.frame = UIScreen.main.bounds
//        gradient.colors = [
//          UIColor(red: 0.139, green: 0.14, blue: 0.154, alpha: 1).cgColor,
//          UIColor(red: 0.034, green: 0.035, blue: 0.042, alpha: 1).cgColor
//        ]
//        gradient.locations = [0, 1]
//        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
//        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
//        
//        gradient.frame = UIScreen.main.bounds
//        layer.insertSublayer(gradient, at: 0)
        
        let myLayer = CALayer()
        let myImage = UIImage(named: "onboarding_main_bg")?.cgImage
        myLayer.frame = UIScreen.main.bounds
        myLayer.contents = myImage
        layer.insertSublayer(myLayer, at: 0)
    }
}
