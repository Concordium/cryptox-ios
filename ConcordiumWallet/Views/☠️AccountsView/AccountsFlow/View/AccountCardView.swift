//
//  AccountCardView.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import UIKit

protocol AccountCardViewDelegate: AnyObject {
    func perform(action: AccountCardAction)
}

enum AccountCardAction {
    case tap
    case send
    case receive
    case earn
    case more
}

//enum AccountCardViewState {
//    case basic
//    case readonly
//    case baking
//    case delegating
//}

@IBDesignable
class AccountCardView: UIView, NibLoadable {
    
    @IBOutlet weak private var widget: WidgetView!
    
    // Contained in accountView
    @IBOutlet weak private var accountName: UILabel!
    @IBOutlet weak var initialAccountLabel: UILabel!
    @IBOutlet weak private var pendingImageView: UIImageView!
    @IBOutlet weak private var accountOwner: UILabel!
    @IBOutlet weak private var stateImageView: UIImageView!
    @IBOutlet weak private var stateLabel: UILabel!
    
    // Contained in totalView
//    @IBOutlet weak private var totalLabel: UILabel!
    @IBOutlet weak private var totalAmount: UILabel!
    @IBOutlet weak private var totalAmountLockImageView: UIImageView!
    
    // Contained in atDisposalView
    @IBOutlet weak private var atDisposalLabel: UILabel!
    @IBOutlet weak private var atDisposalAmount: UILabel!
    
    @IBOutlet weak private var stackCardView: UIStackView!
    
//    @IBOutlet weak private var buttonsHStackViewView: UIStackView!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    
    weak var delegate: AccountCardViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        setupTapCardGesture()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
        setupTapCardGesture()
    }
    
    func setupTapCardGesture() {
        let tapCard = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        stackCardView.addGestureRecognizer(tapCard)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        self.delegate?.perform(action: .tap)
    }
    
    func setup(accountViewModel: AccountViewModel) {
        setupStaticStrings(accountTotal: accountViewModel.totalName,
                           atDisposal: accountViewModel.atDisposalName)
        let state: AccountCardViewState!
        if accountViewModel.isBaking {
            state = .baking
        } else if accountViewModel.isDelegating {
            state = .delegating
        } else if accountViewModel.isReadOnly {
            state = .readonly
        } else {
            state = .basic
        }
        
        let showLock = accountViewModel.totalLockStatus != .decrypted
        
        self.qrButton.isEnabled = accountViewModel.areActionsEnabled
        self.sendButton.isEnabled = accountViewModel.areActionsEnabled
        
        self.setup(accountName: accountViewModel.name,
                   accountOwner: accountViewModel.owner,
                   isInitialAccount: accountViewModel.isInitialAccount,
                   totalAmount: accountViewModel.totalAmount,
                   showLock: showLock,
                   publicBalanceAmount: accountViewModel.generalAmount,
                   atDisposalAmount: accountViewModel.atDisposalAmount,
                   state: state)
    }
    
    private func setupStaticStrings(accountTotal: String,
                                    atDisposal: String
    ) {
//        totalLabel.text = accountTotal
        atDisposalLabel.text = atDisposal
//        buttonsHStackViewView.layer.masksToBounds = true
    }
    
    private func setup(accountName: String?,
                       accountOwner: String?,
                       isInitialAccount: Bool,
                       totalAmount: String,
                       showLock: Bool,
                       publicBalanceAmount: String,
                       atDisposalAmount: String,
                       state: AccountCardViewState) {
        
        self.accountName.text = accountName
        self.accountOwner.text = accountOwner
        
        self.totalAmount.text = publicBalanceAmount
        self.atDisposalAmount.text = atDisposalAmount
        
        initialAccountLabel.isHidden = !isInitialAccount
        
        if showLock {
            self.showLock()
        } else {
            hideLock()
        }
        
        widget.backgroundColor = UIColor.clear
        self.stateLabel.isHidden = false
        self.stateImageView.isHidden = false
        self.stackCardView.alpha = 1
        setTextFontColor(color: .deepBlue)
        switch state {
        case .basic:
            self.stateLabel.isHidden = true
            self.stateImageView.isHidden = true
        case .readonly:
            
            self.stackCardView.alpha = 0.5
            self.stateLabel.text = "accounts.overview.readonly".localized
            self.stateImageView.image = UIImage(named: "icon_read_only")
            setTextFontColor(color: .fadedText)
            widget.backgroundColor = UIColor.clear
        case .baking:
            self.stateLabel.text = "accounts.overview.baking".localized
            self.stateImageView.image = UIImage(named: "icon_bread")
        case .delegating:
            self.stateLabel.text = "accounts.overview.delegating".localized
            self.stateImageView.image = UIImage(named: "icon_delegate")
        }
        
        widget.clipsToBounds = true
        widget.layer.cornerRadius = 24
        
        backgroundColor = .clear
    }
    
    private func setTextFontColor(color: UIColor) {
        for label in [accountName, totalAmount, atDisposalLabel, atDisposalAmount] {
            label?.textColor = color
        }
    }
    
    func showStatusImage(_ statusImage: UIImage?) {
        pendingImageView.image = statusImage
        if statusImage == nil {
            pendingImageView.isHidden = true
        } else {
            pendingImageView.isHidden = false
        }
    }
    
    // MARK: Private
    @IBAction private func pressedSend(sender: Any) {
        delegate?.perform(action: .send)
    }
    
    @IBAction private func pressedReceive(sender: Any) {
        delegate?.perform(action: .receive)
    }

//    @IBAction func pressedEarn(_ sender: Any) {
//        delegate?.perform(action: .earn)
//    }
//
//    @IBAction private func pressedMore(sender: Any) {
//        delegate?.perform(action: .more)
//    }
    
    // MARK: Helpers
    private func showLock() {
        self.totalAmountLockImageView.image = UIImage(named: "Icon_Shield")
        layoutIfNeeded()
    }
    
    private func hideLock() {
        self.totalAmountLockImageView.image = nil
        layoutIfNeeded()
    }
}
