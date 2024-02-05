//
//  TransactionOperationView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 21.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

protocol TransactionOperationViewDelegate: AnyObject { }


@IBDesignable
class TransactionOperationView: UIView, NibLoadable {

  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var detailsLabel: UILabel!
  @IBOutlet private weak var methodView: UIView!
    @IBOutlet private weak var methodLabel: UILabel!


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
          methodView.layer.borderWidth = 1.0
          methodView.layer.borderColor = UIColor.greySecondary.cgColor
          methodView.layer.cornerRadius = 7.0
      }
}


extension TransactionOperationView {
    
    func setup(model: Model.Transaction) {
        var method: String = ""
        if let title = model.data.contract_title {
            method =  title.isEmpty ? "Unknown contract title" : title.replacingOccurrences(of: ".", with: " ")
        } else {
            let title = model.data.contract_method
            method =  title.isEmpty ? "Unknown action" : title.replacingOccurrences(of: "_", with: " ")
        }
        
        methodLabel.text = method
        
        titleLabel.text = ""
        detailsLabel.text = ""
    }

    
    func setup(totalAmount: String) {
        titleLabel.text = totalAmount
        detailsLabel.text = "$0,00"
        //titleLabel.text = GTU(intValue: energy * 10).displayValue() + " CCD"
    }
}
