//
//  TransactionAccountView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 21.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


protocol TransactionAccountViewDelegate: AnyObject { }

@IBDesignable
class TransactionAccountView: UIView, NibLoadable {

  @IBOutlet private weak var bgView: UIView!
  @IBOutlet private weak var imageView: UIImageView!
  @IBOutlet private weak var hashLabel: UILabel!
  @IBOutlet private weak var balanceLabel: UILabel!
    


  weak var delegate: TransactionOperationViewDelegate?
     
     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setupFromNib()
         setup()
     }
     
     override init(frame: CGRect) {
         super.init(frame: frame)
         setupFromNib()
         setup()
     }

     private func setup() {
       
     }

     override func layoutSubviews() {
          super.layoutSubviews()
          imageView.layer.cornerRadius = 21.0
          bgView.layer.cornerRadius = 24.0
      }
    
    
    func setup(acc: AccountDataType?) {

        if let account = acc {
            hashLabel.text = "\(account.displayName) (\(account.address))"  
            balanceLabel.text = "Balance: " + GTU(intValue: account.forecastBalance).displayValue() + " CCD"
            
        } else {
            hashLabel.text = ""
            balanceLabel.text = "Balance: 0 CCD"
        }
        if let iconEncoded = acc?.identity?.identityProvider?.icon {
            imageView.image = UIImage.decodeBase64(toImage: iconEncoded)
        }
    }
}
