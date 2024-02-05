//
//  AirDropWalletCell.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class AirDropWalletCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var hashLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgView.layer.cornerRadius = 21.0
        backView.layer.cornerRadius = 24.0
        layer.cornerRadius = 24.0
    }
    

    
    override func prepareForReuse() {
        backView.backgroundColor = UIColor.greyAdditional.withAlphaComponent(0.1)
    }
    
    
    func setup(account: AccountDataType) {
        hashLabel.text = "\(account.displayName) (\(account.address))"
        balanceLabel.text = "Balance: " + GTU(intValue: account.forecastBalance).displayValue() + " CCD"
        
        if let iconEncoded = account.identity?.identityProvider?.icon {
            imgView.image = UIImage.decodeBase64(toImage: iconEncoded)
        }
    }
}
