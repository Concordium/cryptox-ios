//
//  UIView+Shake.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 11.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


extension UIView {
    func shake(duration: CFTimeInterval) {
        let shakeValues = [-5, 5, -5, 5, -3, 3, -2, 2, 0]

        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x");
        translation.timingFunction = CAMediaTimingFunction(name: .linear)
        translation.values = shakeValues
        
        let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotation.values = shakeValues.map { (Int(Double.pi) * $0) / 180 }
        
        let shakeGroup = CAAnimationGroup()
        shakeGroup.animations = [translation, rotation]
        shakeGroup.duration = 1.0
        layer.add(shakeGroup, forKey: "shakeIt")
    }
}


extension UIView {
    func shake() {
        transform = CGAffineTransform(translationX: 5, y: 0)
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 1,
            options: .curveEaseInOut,
            animations: { [weak self] in
                self?.transform = CGAffineTransform.identity
            }
        )
    }
}
