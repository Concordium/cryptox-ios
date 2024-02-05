//
//  AccountsTotalHeader.swift
//  Mock
//
//  Created by Alex Kudlak on 2021-11-17.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

@IBDesignable
final class AccountsTotalHeader: UIView, NibLoadable {
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalDisposalLabel: UILabel!
    @IBOutlet weak var totalStakedLabel: UILabel!
    @IBOutlet private weak var currencyView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        
        currencyView.layer.cornerRadius = 7
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
}
