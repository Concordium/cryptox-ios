//
//  AccountConfirmationCardView.swift
//  ConcordiumWallet
//
//  Created by Alex Kudlak on 2021-09-05.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

@IBDesignable
class AccountConfirmationCardView: UIView, NibLoadable {
    @IBOutlet weak var currencyView: UIView!
    @IBOutlet var containerView: UIView!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var atDisposalLabel: UILabel!
    @IBOutlet weak var stakedLabel: UILabel!
    @IBOutlet weak var shieldedBalanceLabel: UILabel!
    
    @IBOutlet weak var balanceAmountLabel: UILabel!
    @IBOutlet weak var atDisposalAmountLabel: UILabel!
    @IBOutlet weak var stakedAmountLabel: UILabel!
    @IBOutlet weak var shieldedBalanceAmountLabel: UILabel!
    
    weak var delegate: AccountCardViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    func setupStaticStrings(accountTotal: String,
                            publicBalance: String,
                            atDisposal: String,
                            staked: String,
                            shieldedBalance: String) {
        balanceLabel.text = publicBalance
        atDisposalLabel.text = atDisposal
        stakedLabel.text = staked
        shieldedBalanceLabel.text = shieldedBalance
    }
    
    func setup(accountName: String?,
               accountOwner: String?,
               isInitialAccount: Bool,
               isBaking: Bool,
               isReadOnly: Bool,
               totalAmount: String,
               showLock: Bool,
               publicBalanceAmount: String,
               atDisposalAmount: String,
               stakedAmount: String,
               shieldedAmount: String,
               isExpanded: Bool = false,
               isExpandable: Bool = true) {
        
        balanceAmountLabel.text = publicBalanceAmount
        atDisposalAmountLabel.text = atDisposalAmount
        stakedAmountLabel.text = stakedAmount
        shieldedBalanceAmountLabel.text = shieldedAmount
    }
}
