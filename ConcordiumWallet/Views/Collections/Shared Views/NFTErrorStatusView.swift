//
//  NFTErrorStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

protocol NFTErrorStatusViewDelefate: AnyObject {
    func didTapBack(form: NFTErrorStatusView)
}


class NFTErrorStatusView: UIView, NibLoadable {
    var delegate: NFTErrorStatusViewDelefate?
}

extension NFTErrorStatusView {
    
    @IBAction func  didTapBack() {
        delegate?.didTapBack(form: self)
    }
}


// MARK: - instantie
extension NFTErrorStatusView {
    
    class func instantie(delegate: NFTErrorStatusViewDelefate? = nil) -> NFTErrorStatusView {
        let view =  NFTErrorStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
