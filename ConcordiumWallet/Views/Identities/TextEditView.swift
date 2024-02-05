//
//  TextEditView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

protocol TextEditViewDelegate: AnyObject {
    func buttonDidTapped(_ sender: TextEditView)
}


@IBDesignable
class TextEditView: UIView, NibLoadable {

    weak var delegate: TextEditViewDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var messageLabel: UILabel!


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
}


extension TextEditView: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        messageLabel.text = nil
        
        return true
    }
}


extension TextEditView {
    
    @IBAction func buttonDidTapped(_ sender: AnyObject) {
        delegate?.buttonDidTapped(self)
    }
    
    func set(title: String, placeholder: String, buttonIcon: String? = nil) {
        titleLabel.text = title
        textField.placeholder = placeholder
        if let iconName = buttonIcon {
            button.setImage(UIImage(named: iconName), for: .normal)
        } else {
            button.isHidden = true
        }
    }
    
    func set(message: String?) {
        messageLabel.text = message
    }
    
    
}

