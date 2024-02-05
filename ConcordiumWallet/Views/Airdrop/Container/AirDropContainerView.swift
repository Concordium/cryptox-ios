//
//  AirDropViewContainer.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import UIKit


protocol AirDropContainerViewDelegate: AnyObject {
    
    func cancel(from: AirDropContainerView)
    func connect(from: AirDropContainerView)
    func perform(from: AirDropContainerView)
    func didSelect(from: AirDropContainerView, model: AccountDataType)
    func done(from: AirDropContainerView)
}


class AirDropContainerView: GradientBGView, NibLoadable {
    
    private weak var delegate: AirDropContainerViewDelegate? = nil
  
    @IBOutlet private weak var hostLabel: UILabel!
    @IBOutlet private weak var marketplaceLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var stateView: UIView!


    private lazy var walletsView: AirDropWalletsView = {
        AirDropWalletsView.instantie(delegate: self)
    }()
    private lazy var connectView: AirDropConnectView = {
        AirDropConnectView.instantie(delegate: self)
    }()
    private lazy var resultView: AirDropResultView = {
        AirDropResultView.instantie(delegate: self)
    }()
    
    init(action delegate: AirDropContainerViewDelegate? = nil) {
        super.init(frame: .zero)
        self.delegate = delegate
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}


extension AirDropContainerView {
    
    private func setup() {
        for subView in [connectView, walletsView, resultView] {
            stateView.addSubview(subView)
            subView.isHidden = true

            subView.translatesAutoresizingMaskIntoConstraints = false
            
            subView.topAnchor.constraint(equalTo: stateView.topAnchor, constant: 0).isActive = true
            subView.bottomAnchor.constraint(equalTo: stateView.bottomAnchor, constant: 0).isActive = true
            subView.leadingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: 0).isActive = true
            subView.trailingAnchor.constraint(equalTo: stateView.trailingAnchor, constant: 0).isActive = true
        }
    }
}


extension AirDropContainerView {
 
    func update(with model: Model.Flyer) {
        hostLabel.text = model.marketplaceName
        marketplaceLabel.text = model.airdropName
        guard let url = URL(string: model.marketplaceIcon) else { return }
        imageView.kf.setImage(with: url)
    }
}


//MARK: - Show

extension AirDropContainerView {

    func show(view: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.stateView.subviews.forEach {item in
                item.isHidden = (view != item)
            }
        }
    }
    
    
    func showWallets(items: [AccountDataType]) {
        walletsView.accs = items
        show(view: walletsView)
    }

    func showConnectView() {
        show(view: connectView)
    }

    func showResultView(status: Bool, message: String) {
        resultView.update(message: message, with: status)
        show(view: resultView)
    }
}

// MARK: - AirDropContainerView
extension AirDropContainerView {
    @IBAction func didTapClose() {
        delegate?.cancel(from: self)
    }
}

// MARK: - AirDropWalletsViewDelegate
extension AirDropContainerView: AirDropWalletsViewDelegate {
    func cancel(from: AirDropWalletsView) {
        delegate?.cancel(from: self)
    }
    
    func connect(from: AirDropWalletsView) {
        delegate?.perform(from: self)
    }
    
    func didTap(from: AirDropWalletsView, with model: AccountDataType) {
        delegate?.didSelect(from: self, model: model)
    }
}

// MARK: - AirDropConnectViewDelegate
extension AirDropContainerView: AirDropConnectViewDelegate {
    func cancel(from: AirDropConnectView) {
        delegate?.cancel(from: self)
    }
    
    func connect(from: AirDropConnectView) {
        delegate?.connect(from: self)
    }
}

// MARK: - AirDropResultViewDelegate
extension AirDropContainerView: AirDropResultViewDelegate {
    func done(from: AirDropResultView) {
        delegate?.done(from: self)
    }
}


// MARK: - instantie
extension AirDropContainerView {
    
    class func instantie(delegate :AirDropContainerViewDelegate? = nil) -> AirDropContainerView {
        let view =  AirDropContainerView.loadFromNib()
        view.delegate = delegate
        view.setup()
        return view
    }
}
