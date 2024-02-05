//
//  AirDropConnectView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol AirDropConnectViewDelegate: AnyObject {
    
    func cancel(from: AirDropConnectView)
    func connect(from: AirDropConnectView)
}


class AirDropConnectView: UIView, NibLoadable {
    
    private weak var delegate: AirDropConnectViewDelegate? = nil
    
    @IBOutlet private weak var calcelButton: UIButton!
  	@IBOutlet private weak var connectButton: UIButton!
    
}

// MARK: – Setup
extension AirDropConnectView {
    
    func setup() {
        calcelButton.layer.cornerRadius = 26
        connectButton.layer.cornerRadius = 26
        
        calcelButton.layer.borderWidth = 1
        calcelButton.layer.borderColor = UIColor(red: 0.831, green: 0.839, blue: 0.863, alpha: 1).cgColor
    }
}


// MARK: – Actions
extension AirDropConnectView {
    
    @IBAction func didTapCancel() {
        delegate?.cancel(from: self)
    }
    
    @IBAction func didTapConnect() {
        delegate?.connect(from: self)
    }
}


// MARK: - instantie
extension AirDropConnectView {
    
    class func instantie(delegate :AirDropConnectViewDelegate? = nil) -> AirDropConnectView {
        let view =  AirDropConnectView.loadFromNib()
        view.delegate = delegate
        view.setup()
        return view
    }
}
