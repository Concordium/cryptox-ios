//
//  VersionView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 12.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


@IBDesignable
class VersionView: UIView, NibLoadable {

    
    @IBOutlet weak var titleLabel: UILabel!


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
}
