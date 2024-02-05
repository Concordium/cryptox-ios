//
//  TransactionDetailsView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 21.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


protocol TransactionDetailsViewDelegate: AnyObject {
    func didTapEdit()
    func didTapShowData()
}

@IBDesignable
class TransactionDetailsView: UIView, NibLoadable {
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var networkComissionLabel: UILabel!
    @IBOutlet private weak var totalAmountLabel: UILabel!
    @IBOutlet private weak var estimatedInUSDComissionLabel: UILabel!
    @IBOutlet private weak var editLabel: UILabel! {
        didSet { setupEditAction() } }
    
    @IBOutlet private weak var amountValuesLabel: UILabel!
    @IBOutlet private weak var aproximateFeeValuesLabel: UILabel!
    @IBOutlet private weak var maxFeeValuesLabel: UILabel!
    @IBOutlet private weak var totalAmountValuesLabel: UILabel!
    @IBOutlet private weak var estimatedInUSDComissionValuesLabel: UILabel!
    @IBOutlet private weak var showDataLabel: UILabel! {
        didSet { setupShowDataAction() } }
    
    
    weak var delegate: TransactionDetailsViewDelegate?
    
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
        bgView.layer.cornerRadius = 24.0
    }
}


extension TransactionDetailsView {
    
    private func setupEditAction() {
        let gestureTo = UITapGestureRecognizer(target: self, action:  #selector (self.editAction(_:)))
        editLabel.isUserInteractionEnabled = true
        editLabel.addGestureRecognizer(gestureTo)
    }
    
    private func setupShowDataAction() {
        let gestureTo = UITapGestureRecognizer(target: self, action:  #selector (self.showDataAction(_:)))
        showDataLabel.isUserInteractionEnabled = true
        showDataLabel.addGestureRecognizer(gestureTo)
    }
}

extension TransactionDetailsView {
    
    @objc func editAction(_ sender: UIButton) {
        delegate?.didTapEdit()
    }
    
    @objc func showDataAction(_ sender: UIButton) {
        delegate?.didTapShowData()
    }
}


extension TransactionDetailsView {
    
    func setup(model: Model.Transaction) {
        amountValuesLabel.text = "0,00 CCD"
        aproximateFeeValuesLabel.text = "0,00 CCD"
        maxFeeValuesLabel.text = "0,00 CCD"
        totalAmountValuesLabel.text = "0,00 CCD"
    }
    
    func setup(amount: String, aproximateFee: String, maxFee: String, totalAmount: String) {
        amountValuesLabel.text = amount + " CCD"
        aproximateFeeValuesLabel.text = aproximateFee + " CCD"
        maxFeeValuesLabel.text = "up to " + maxFee + " CCD"
        totalAmountValuesLabel.text = totalAmount + " CCD"
    }
}
