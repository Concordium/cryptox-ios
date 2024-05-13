//
//  QRTransactionDataViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 08.11.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

class QRTransactionDataViewController: UIViewController {

    
    @IBOutlet private weak var detailsView: UIView!
    @IBOutlet private weak var methodNameLabel: UILabel!
    @IBOutlet private weak var hexDataLabel: UILabel!
    @IBOutlet private weak var buttonGotIt: FilledButton!

    let methodName: String
    let hexData: String
    let compleation: (()->Void)?
    
    
    init(method name: String, hex data: String, compleation: (()->Void)?) {
        self.methodName = name
        self.hexData = data
        self.compleation = compleation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        methodNameLabel.text = methodName
        hexDataLabel.text = hexData
        buttonGotIt.setTitle("okay.gotit".localized, for: .normal)
        
        detailsView.layer.cornerRadius = 24.0
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        navigationItem.hidesBackButton = true
        setupCopyAction()
    }
    
    private func setupCopyAction() {
        let gestureTo = UITapGestureRecognizer(target: self, action:  #selector (self.copyButtonTapped(_:)))
        hexDataLabel.isUserInteractionEnabled = true
        hexDataLabel.addGestureRecognizer(gestureTo)
    }
    
    @IBAction func didTapGotIt() {
        
        compleation?()
    }

}


extension QRTransactionDataViewController: ShowToast {
    
    @objc private func copyButtonTapped(_ sender: UIButton) {
        UIPasteboard.general.string = hexData
        showToast(withMessage: "accountAddress.toast.addressCopied".localized, backgroundColor: UIColor.greenMain)
    }
}
