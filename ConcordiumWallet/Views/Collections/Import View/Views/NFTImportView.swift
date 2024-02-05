//
//  NFTImportView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 05.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTImportView: GradientBGView {
    
    private weak var actionDelegate: ActionProtocol?
    
    private lazy var inputDataView: NFTInputStatusView = {
        NFTInputStatusView.instantie(delegate: self)
    }()
    private lazy var errorView: NFTErrorStatusView = {
        NFTErrorStatusView.instantie(delegate: self)
    }()
    private lazy var emptyView: NFTEmptyStatusView = {
        NFTEmptyStatusView.instantie(delegate: self)
    }()
    private lazy var loadingView: NFTLoadingStatusView = {
        NFTLoadingStatusView.instantie()
    }()
    public lazy var dataView: NFTDataStatusView = {
        NFTDataStatusView.instantie(delegate: self)
    }()

    

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(NFTImportView.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        
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


extension NFTImportView {
    
    private func setup() {
        
        compleations()
        
        for subView in [loadingView, emptyView, dataView, errorView, inputDataView] {
            self.addSubview(subView)
            subView.isHidden = true
            
            subView.translatesAutoresizingMaskIntoConstraints = false
            
            subView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
            subView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
            subView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
            subView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        }
    }
    
    private func compleations() {
        
        inputDataView.setup()
    }

}

//MARK: - Show

extension NFTImportView {

    func show(view: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.subviews.forEach {item in
                item.isHidden = (view != item)
            }
        }
    }
    
    
    func showInputView() {
        show(view: inputDataView)
    }

    func showResults(items: [NFTImport.Section]) {
        endRefreshing()
        show(view: dataView)
        DispatchQueue.main.async { [weak self] in
            self?.dataView.update(with: items)
        }
    }

    func showLoadingView() {
        show(view: loadingView)
        loadingView.startAnimating()
    }

    func showEmptyView() {
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
extension NFTImportView {
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) { }
}



// MARK: – NFTInputStatusViewDelegate
extension NFTImportView: NFTInputStatusViewDelegate {
    
    func didTapNext(form: NFTInputStatusView, with address: String, provider name: String) {
        let action = NFTImport.Action.fetch(address: address, name: name)
        actionDelegate?.didInitiate(action: action)
        
        emptyView.update(with: name)
    }
}


// MARK: – NFTErrorStatusViewDelefate
extension NFTImportView: NFTErrorStatusViewDelefate {
    
    func didTapBack(form: NFTErrorStatusView) {
        showInputView()
    }
}


// MARK: – NFTEmptyStatusViewDelefate
extension NFTImportView: NFTEmptyStatusViewDelefate {
    
    func didTapBack(form: NFTEmptyStatusView) {
        showInputView()
    }
}

// MARK: – NFTDataStatusViewDelegate
extension NFTImportView: NFTDataStatusViewDelegate {
    
    func didTap(from: NFTDataStatusView, with model: NFTTokenViewModel) {
        let action = NFTImport.Action.open(item: model)
        actionDelegate?.didInitiate(action: action)
    }
}
