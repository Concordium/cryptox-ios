//
//  NFTInputStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit
import Combine


protocol NFTInputStatusViewDelegate: AnyObject {
    func didTapNext(form: NFTInputStatusView, with address: String, provider name: String)
}


class NFTInputStatusView: UIView, NibLoadable, UITextViewDelegate {
    weak var delegate: NFTInputStatusViewDelegate?
    
    
    @IBOutlet private weak var infoView: UIView!
    @IBOutlet private weak var supportTextView: UITextView!
    @IBOutlet private weak var urlTextView :TextEditView!
    @IBOutlet private weak var nameTextView :TextEditView!
    @IBOutlet private weak var nextButton: FilledButton!
    
    private var cancellableArray = [AnyCancellable]()
    private lazy var urlTextField: UITextField = {
        urlTextView.textField
    }()
	
    private lazy var nameTextField: UITextField = {
        nameTextView.textField
    }()
    
    func setup() {
        urlTextField.textContentType = .URL
        let links = ["spaceseven.com": "https://spaceseven.com"]

        let supportText = "nft.import.info".localized
        supportTextView.addHyperLinksToText(originalText: supportText, hyperLinks: links)
        supportTextView.textContainerInset = UIEdgeInsets.zero
        supportTextView.textContainer.lineFragmentPadding = 0
        supportTextView.delegate = nil
        supportTextView.isUserInteractionEnabled = false
        
        
        urlTextView.set(title: "nft.import.url.title".localized, placeholder: "nft.import.url.placeholder".localized)
        urlTextView.set(message: nil)
        urlTextView.textField.text = nil
        
        nameTextView.set(title: "nft.import.name.title".localized, placeholder: "nft.import.name.placeholder".localized)
        nameTextView.set(message: nil)
        nameTextView.textField.text = nil
        
        nextButton.isEnabled = !(urlTextField.text?.isEmpty ?? true)
        urlTextField.textPublisher
            .receive(on: DispatchQueue.main)
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: nextButton)
            .store(in: &cancellableArray)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        infoView.layer.borderColor = UIColor.success.cgColor
        infoView.layer.borderWidth = 1.0
        infoView.layer.cornerRadius = 14.0
    }
}


extension NFTInputStatusView {
 
    @IBAction func didNextTap() {
        if let address = urlTextField.text, let name = nameTextField.text {
            delegate?.didTapNext(form: self, with: address, provider: name)
        }
    }
}


// MARK: - instantie
extension NFTInputStatusView {
    
    class func instantie(delegate: NFTInputStatusViewDelegate? = nil) -> NFTInputStatusView {
        let view =  NFTInputStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}

