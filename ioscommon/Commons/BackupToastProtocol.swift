//
//  BackupToastProtocol.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 25.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol BackupToastProtocol: AnyObject {
    func showBackupWarning(toastMessage: String, in viewController: UIViewController)
    func dismissBackupWarning(in viewController: UIViewController)
}


extension AccountsViewController {
    
    func showBackupWarning(toastMessage: String, in viewController: UIViewController) {
        guard let view = viewController.view else { return }
        if let toastView = view.viewWithTag(555), toastView is ToastLabel {
            return
        }
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        OperationQueue.main.addOperation({
            let toastView = ToastLabel()
            toastView.isUserInteractionEnabled = true
            toastView.addGestureRecognizer(tapRecognizer)
            toastView.tag = 555
            toastView.font = UIFont.satoshi(size: 14, weight: .medium)
            toastView.text = toastMessage
            toastView.textColor = UIColor.blackMain
            toastView.backgroundColor = UIColor.yellowMain
            toastView.textAlignment = .center
            toastView.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: 0)
            toastView.layer.cornerRadius = 0
            toastView.layer.masksToBounds = true
            toastView.center = view.center
            toastView.minimumScaleFactor = 0.5
            toastView.numberOfLines = 0
            toastView.adjustsFontSizeToFitWidth = true
            toastView.setYPosition((view.frame.size.height - view.safeAreaInsets.bottom))

            view.addSubview(toastView)
            UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut, animations: {
                var newFrame = toastView.frame
                newFrame.size.height = 48.0
                newFrame.origin.y = (view.frame.size.height - view.safeAreaInsets.bottom) - 48
                toastView.frame = newFrame
            }, completion: { _ in })
        })
    }
    
    
    func dismissBackupWarning(in viewController: UIViewController) {
        guard let view = viewController.view else { return }
        guard let toastView = view.viewWithTag(555), toastView is ToastLabel else {
            return
        }
        
        OperationQueue.main.addOperation({
            UIView.animate(withDuration: 0.5, delay: 0.7, options: .curveEaseOut) {
                var newFrame = toastView.frame
                newFrame.size.height = 0.0
                newFrame.origin.y = (view.frame.size.height - view.safeAreaInsets.bottom) + 48
                toastView.frame = newFrame
            } completion: { _ in
                toastView.removeFromSuperview()
            }
        })
    }

}
