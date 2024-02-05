//
//  QRTransactionBuyView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 15.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


class QRTransactionBuyView: UIView, NibLoadable {
 
    weak var actionDelegate: ActionProtocol?

    @IBOutlet private weak var operationView: TransactionOperationView!
    @IBOutlet private weak var accountView: TransactionAccountView!
    @IBOutlet private weak var detailsView: TransactionDetailsView! {
        didSet { detailsView.delegate = self }
    }
    @IBOutlet private weak var nrgCCDAmountLabel: UILabel!

  

    // Amount
    //NetworkComission
    
    init(action delegate: ActionProtocol? = nil) {
        super.init(frame: .zero)
        setupFromNib()
        self.actionDelegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}


extension QRTransactionBuyView {

    func show(model: Model.Transaction, accs: [AccountDataType]?) {
        operationView.setup(model: model)
        let acc = accs?.filter{ $0.address == model.data.from }.first
        accountView.setup(acc: acc)
        detailsView.setup(model: model)
    }
    
    func setup(model: Model.Transaction, energy: Int, fee: Int, cost: Int, nrgCCDAmount: Int) {
        let amount  = Int(model.data.amount) ?? 0
        let networkComission = nrgCCDAmount
        let aproximateComission = ceil(Double(nrgCCDAmount) / 3.0)
        
        let ccdAmount =  GTU(intValue: amount)
        let ccdNetworkComission = GTU(displayValue: networkComission.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdMaxFee = ccdNetworkComission
        let ccdAproximateFee = GTU(displayValue: Int(aproximateComission).toString())
        
        operationView.setup(totalAmount: ccdTotalAmount.displayValue())
        detailsView.setup(amount: ccdAmount.displayValue(), aproximateFee: ccdAproximateFee.displayValue() , maxFee: ccdMaxFee.displayValue(), totalAmount: ccdTotalAmount.displayValue())
    }
}


extension QRTransactionBuyView: TransactionDetailsViewDelegate {
    
    func didTapEdit() {
        actionDelegate?.didInitiate(action: QRTransaction.Action.edit)
    }
    
    func didTapShowData() {
        actionDelegate?.didInitiate(action: QRTransaction.Action.showData)
    }
    
}
