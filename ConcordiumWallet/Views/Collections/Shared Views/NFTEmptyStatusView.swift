//
//  NFTEmptyStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol NFTEmptyStatusViewDelefate: AnyObject {
    func didTapBack(form: NFTEmptyStatusView)
}


class NFTEmptyStatusView: UIView, NibLoadable {
    var delegate: NFTEmptyStatusViewDelefate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
}

extension NFTEmptyStatusView {
    
    func update(with address: String) {
        infoLabel.text = address
    }
    
    func update(with title: String, and address: String) {
        titleLabel.text = title
        infoLabel.text = address
        actionButton.isHidden = true
    }
}


extension NFTEmptyStatusView {
    
    @IBAction func didBackTap() {
        delegate?.didTapBack(form: self)
    }
}


// MARK: - instantie
extension NFTEmptyStatusView {
    
    class func instantie(delegate :NFTEmptyStatusViewDelefate? = nil) -> NFTEmptyStatusView {
        let view =  NFTEmptyStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
