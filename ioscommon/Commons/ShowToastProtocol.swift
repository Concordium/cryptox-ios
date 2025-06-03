//
// Created by Concordium on 13/05/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation
import UIKit

protocol ShowToast: AnyObject {
    func showToast(withMessage toastMessage: String?, backgroundColor: UIColor, centeredIn view: UIView?, time: Double?)
}

extension ShowToast {

    func showToast1(withMessage toastMessage: String?, backgroundColor: UIColor = UIColor.pinkyMain, centeredIn view: UIView? = (UIApplication.shared.delegate as? AppDelegate)?.window, time: Double? = 1) {
        OperationQueue.main.addOperation({
            let toastView = ToastLabel()
            toastView.font = UIFont.satoshi(size: 14, weight: .medium)
            toastView.text = toastMessage
            toastView.backgroundColor = backgroundColor
            toastView.textAlignment = .center
            toastView.frame = CGRect(x: 0.0, y: 0.0, width: (view?.frame.size.width ?? 0.0), height: 48.0)
            toastView.layer.cornerRadius = 0
            toastView.layer.masksToBounds = true
            toastView.center = view?.center ?? CGPoint.zero
            toastView.minimumScaleFactor = 0.5
            toastView.numberOfLines = 0
            toastView.adjustsFontSizeToFitWidth = true
            toastView.setYPosition((view?.safeAreaInsets.top ?? 56) + 56)

            view?.addSubview(toastView)
            UIView.animate(withDuration: 1.0, delay: time ?? 0.3, options: .curveEaseOut, animations: {
                toastView.alpha = 0.0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        })
    }
    
    func showToast(withMessage toastMessage: String?, backgroundColor: UIColor = UIColor.pinkyMain, centeredIn view: UIView? = (UIApplication.shared.delegate as? AppDelegate)?.window, time: Double? = 1) {
        OperationQueue.main.addOperation({
            let toastView = ToastLabel()
            toastView.font = UIFont.satoshi(size: 14, weight: .medium)
            toastView.text = toastMessage
            toastView.backgroundColor = backgroundColor
            toastView.textAlignment = .center
            toastView.frame = CGRect(x: 0.0, y: 0.0, width: (view?.frame.size.width ?? 0.0), height: 0.0)
            toastView.layer.cornerRadius = 0
            toastView.layer.masksToBounds = true
            toastView.center = view?.center ?? CGPoint.zero
            toastView.minimumScaleFactor = 0.5
            toastView.numberOfLines = 0
            toastView.adjustsFontSizeToFitWidth = true
            toastView.setYPosition((view?.safeAreaInsets.top ?? 56) + 56)

            view?.addSubview(toastView)
            UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseOut, animations: {
                var newFrame = toastView.frame
                newFrame.size.height = 48.0
                toastView.frame = newFrame
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, delay: 0.7, options: .curveEaseOut) {
                    var newFrame = toastView.frame
                    newFrame.size.height = 0.0
                    toastView.frame = newFrame
                } completion: { _ in
                    toastView.removeFromSuperview()
                }
            })
        })
    }
}
