//
//  NFTProvidersView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTProvidersView: GradientBGView {
    
    private weak var actionDelegate: ActionProtocol?
    
    private lazy var errorView: NFTErrorStatusView = {
        NFTErrorStatusView.instantie(delegate: self)
    }()
    private lazy var emptyView: NFTEmptyStatusView = {
        NFTEmptyStatusView.instantie(delegate: self)
    }()
    private lazy var loadingView: NFTLoadingStatusView = {
        NFTLoadingStatusView.instantie()
    }()
    public lazy var tokensView: NFTTokensStatusView = {
        NFTTokensStatusView.instantie(delegate: self)
    }()
    public lazy var itemsView: NFTItemsStatusView = {
        NFTItemsStatusView.instantie(delegate: self)
    }()
    

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(NFTProvidersView.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        
        return refreshControl
    }()
    
    init(action delegate: ActionProtocol? = nil) {
        super.init(frame: .zero)
        self.actionDelegate = delegate
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}


extension NFTProvidersView {
    
    private func setup() {
        
        compleations()
        itemsView.setup(refreshControl: refreshControl)
        
        for subView in [loadingView, emptyView, tokensView, errorView, itemsView] {
            self.addSubview(subView)
            subView.isHidden = true
            
            subView.translatesAutoresizingMaskIntoConstraints = false
            
            subView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
            subView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
            subView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
            subView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        }
    }
    
    private func compleations() { }
}

//MARK: - Show

extension NFTProvidersView {

    func show(view: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.subviews.forEach {item in
                item.isHidden = (view != item)
            }
        }
    }
    
    
    func showResults(items: [NFTProviders.Section], mode: NFTProviders.Mode) {
        endRefreshing()
        switch mode {
        case .marketplace, .wallet:
            itemsView.update(with: items)
            show(view: itemsView)
        case .tokens:
            tokensView.update(with: items)
            show(view: tokensView)
        }
    }

    func showLoadingView() {
        show(view: loadingView)
        loadingView.startAnimating()
    }

    func showEmptyView() {
        emptyView.update(with: "Tokens not found", and: "")
        show(view: emptyView)
    }
    
    func showErrorView() {
        show(view: errorView)
    }
    
    func endRefreshing() {
        refreshControl.endRefreshing()
    }
}



// Refresh
extension NFTProvidersView {
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        let action = NFTProviders.Action.fetch(forceReload: true)
        actionDelegate?.didInitiate(action: action)
    }
}



// MARK: – NFTInputStatusViewDelegate
extension NFTProvidersView: NFTInputStatusViewDelegate {
    
    func didTapNext(form: NFTInputStatusView, with address: String, provider name: String) {
        let action = NFTImport.Action.fetch(address: address, name: name)
        actionDelegate?.didInitiate(action: action)
        
        emptyView.update(with: name)
    }
}


// MARK: – NFTErrorStatusViewDelefate
extension NFTProvidersView: NFTErrorStatusViewDelefate {
    
    func didTapBack(form: NFTErrorStatusView) {
        let action = NFTProviders.Action.fetch(forceReload: true)
        actionDelegate?.didInitiate(action: action)
    }
}


// MARK: – NFTEmptyStatusViewDelefate
extension NFTProvidersView: NFTEmptyStatusViewDelefate {
    
    func didTapBack(form: NFTEmptyStatusView) {
        let action = NFTProviders.Action.fetch(forceReload: true)
        actionDelegate?.didInitiate(action: action)
    }
}

// MARK: – NFTDataStatusViewDelegate
extension NFTProvidersView: NFTTokensStatusViewDelegate {
    
    func didTap(from: NFTTokensStatusView, with model: NFTTokenViewModel) {
        let action = NFTProviders.Action.openToken(model: model)
        actionDelegate?.didInitiate(action: action)
    }
    
    func didChangeSearch(from: NFTTokensStatusView, with text: String) {
        
        let action = NFTProviders.Action.search(text)
        actionDelegate?.didInitiate(action: action)
    }
}


// MARK: – NFTItemsStatusViewDelegate
extension NFTProvidersView: NFTItemsStatusViewDelegate {
    
    func didTap(from: NFTItemsStatusView, with model: NFTMarketplaceViewModel) {
        let action = NFTProviders.Action.openMarketplace(model: model)
        actionDelegate?.didInitiate(action: action)
    }
    
    func didTap(from: NFTItemsStatusView, with model: NFTWalletViewModel) {
        let action = NFTProviders.Action.openWallet(model: model)
        actionDelegate?.didInitiate(action: action)
    }
    
    func delete(from: NFTItemsStatusView, with model: NFTMarketplaceViewModel) {
        let action = NFTProviders.Action.delete(model: model)
        actionDelegate?.didInitiate(action: action)
    }
}
