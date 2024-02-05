//
//  NFTLoadingStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

protocol NFTLoadingStatusViewDelegate: AnyObject { }


class NFTLoadingStatusView: UIView, NibLoadable {
    var delegate: NFTLoadingStatusViewDelegate?
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
}


extension NFTLoadingStatusView {
    
    func startAnimating() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimationg() {
        activityIndicator.stopAnimating()
    }
}


// MARK: - instantie
extension NFTLoadingStatusView {
    
    class func instantie(delegate :NFTLoadingStatusViewDelegate? = nil) -> NFTLoadingStatusView {
        let view =  NFTLoadingStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
