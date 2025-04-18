//
// Created by Concordium on 15/03/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func setYPosition(_ yPos: CGFloat) {
        self.frame.origin.y = yPos
    }
    
    func setBottom(_ bottomPos: CGFloat) {
        self.frame.origin.y = bottomPos - self.frame.size.height
    }
    
    func setXPosition(_ xPos: CGFloat) {
        self.frame.origin.x = xPos
    }
    
    func translateYPosition(_ dist: CGFloat) {
        self.frame.origin.y += dist
    }
    
    func translateXPosition(_ dist: CGFloat) {
        self.frame.origin.x += dist
    }
}

extension UIView {
    
    func setHiddenIfChanged(_ value: Bool) {
        if !isHidden && value || isHidden && !value {
            isHidden = value
        }
    }
    
    func makeSecure() {
        DispatchQueue.main.async {
            let field = UITextField()
            field.isSecureTextEntry = true
            self.addSubview(field)
            field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            self.layer.superlayer?.addSublayer(field.layer)
            field.layer.sublayers?.first?.addSublayer(self.layer)
        }
    }
}

extension UIView {
    func setFadeAnimation() {
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = .fade
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        self.layer.add(transition, forKey: kCATransition)
    }
}
