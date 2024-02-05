//
//  NFTEmptySearchStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 22.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTEmptSearchStatusView: UIView, NibLoadable {
    
    @IBOutlet private weak var infoLabel: UILabel!
    
}

extension NFTEmptSearchStatusView {
    
    func update(with request: String) {
        infoLabel.text = "nft.import.emptysearch.info".localized + "\(request)"
    }
}


// MARK: - instantie
extension NFTEmptSearchStatusView {
    
    class func instantie() -> NFTEmptSearchStatusView {
        let view =  NFTEmptSearchStatusView.loadFromNib()
        return view
    }
}
