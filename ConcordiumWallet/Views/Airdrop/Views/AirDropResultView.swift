//
//  AirDropResultView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol AirDropResultViewDelegate: AnyObject {
    
    func done(from: AirDropResultView)
}


class AirDropResultView: UIView, NibLoadable {
    
    private weak var delegate: AirDropResultViewDelegate? = nil
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    
    @IBOutlet private weak var continueButton: UIButton!
}

// MARK: – Setup
extension AirDropResultView {
    
    func setup() {
        continueButton.layer.cornerRadius = 26
    }
    
    func update(message: String, with state: Bool) {
        titleLabel.text = nil//"airdrop.success.title".localized //state ? "airdrop.success.title".localized : "airdrop.error.title".localized
        messageLabel.text = message
    }
}


// MARK: – Actions
extension AirDropResultView {
    
    @IBAction func didTapDone() {
        delegate?.done(from: self)
    }
}


// MARK: - instantie
extension AirDropResultView {
    
    class func instantie(delegate :AirDropResultViewDelegate? = nil) -> AirDropResultView {
        let view =  AirDropResultView.loadFromNib()
        view.delegate = delegate
        view.setup()
        return view
    }
}
