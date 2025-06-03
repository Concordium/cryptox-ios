//
//  QRTransactionView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 15.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit



class QRTransactionView: UIView, NibLoadable {
    
    weak var actionDelegate: ActionProtocol?
    
    // header
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    // changable content
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var continueButton: FilledButton!

    
    private let buyView: QRTransactionBuyView
    

    init(action delegate: ActionProtocol? = nil) {
        self.buyView  = QRTransactionBuyView(action: delegate)
        super.init(frame: .zero)
        setupFromNib()
        self.actionDelegate = delegate
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.buyView  = QRTransactionBuyView(action: actionDelegate)
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        self.buyView  = QRTransactionBuyView(action: actionDelegate)
        super.init(frame: frame)
        setupFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}


extension QRTransactionView {
    
    @IBAction func cancellAction(_ sender: UIButton) {
        actionDelegate?.didInitiate(action: QRTransaction.Action.cancel)
   }

   @IBAction func connectAction(_ sender: UIButton) {
       actionDelegate?.didInitiate(action: QRTransaction.Action.accept)
   }
}


extension QRTransactionView {

        func setup() {
            
            for subView in [buyView] {
                contentView.addSubview(subView)
                subView.isHidden = true

                subView.translatesAutoresizingMaskIntoConstraints = false

                subView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
                subView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0).isActive = true
                subView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
                subView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
            }
        }
}


extension QRTransactionView {
    func disableContinueButton() {
        continueButton.isUserInteractionEnabled = false
    }
    
    func show(view: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.contentView.subviews.forEach {item in
                item.isHidden = (view != item)
            }
        }
    }
    
    
    func show(model: Model.Transaction, accs: [AccountDataType]?, connectionData: QRDataResponse?) {
        show(header: connectionData)
        show(model: model, accs: accs)
    }
    
    func shot(model: Model.Transaction, energy: Int, fee: Int, cost: Int, nrgCCDAmount: Int) {
        buyView.setup(model: model, energy: energy, fee: fee, cost: cost, nrgCCDAmount: nrgCCDAmount)
    }
    
    
    private func show(header connectionData: QRDataResponse?) {
        titleLabel.text = connectionData?.site.title
        descriptionLabel.text = connectionData?.site.description
        if let urlStr = connectionData?.site.icon_link, let url = URL(string: urlStr) {
            imgView.tintColor = UIColor.greyAdditional
            imgView.load(url: url, renderingMode: .alwaysTemplate)
        }
    }
    
    
    private func show(model: Model.Transaction, accs: [AccountDataType]?) {
        buyView.show(model: model, accs: accs)
        show(view: buyView)
    }
    
}

