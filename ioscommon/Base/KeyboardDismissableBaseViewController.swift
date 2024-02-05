//
//  KeyboardDismissableBaseViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 12.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//


import UIKit

class KeyboardDismissableBaseViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedView))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func tappedView() {
        didDismissKeyboard()
    }

    func didDismissKeyboard() {
        view.endEditing(true)
    }
}
