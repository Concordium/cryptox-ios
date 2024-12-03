//
//  NFTProvidersViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTProvidersFactory {
    class func create(with presenter: NFTProvidersPresenterProtocol, mode: NFTProviders.Mode, configureAccountAlertDelegate: ConfigureAccountAlertDelegate?) -> NFTProvidersViewController {
        NFTProvidersViewController.instantiate(fromStoryboard: "Collections") { coder in
            return NFTProvidersViewController(coder: coder, presenter: presenter, mode: mode, configureAccountAlertDelegate: configureAccountAlertDelegate)
        }
    }
}


protocol NFTProvidersDisplayLogic: AnyObject {
    func display(state: NFTProviders.ViewControllerState)
}


class NFTProvidersViewController: BaseViewController, Storyboarded, SpecificViewForController {
    typealias View = NFTProvidersView
    
    private var state: NFTProviders.ViewControllerState = .loading

    let mode: NFTProviders.Mode
    var presenter: NFTProvidersPresenterProtocol?
    weak var configureAccountAlertDelegate: ConfigureAccountAlertDelegate?
    
    private lazy var searchBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "search")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.searchTapped))
    }()
    
    private lazy var backBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "backButtonIcon")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.backTapped))
    }()
    
    private lazy var addProviderTBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "add")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.addProviderTapped))
    }()
    
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)

        search.obscuresBackgroundDuringPresentation = true
        search.hidesNavigationBarDuringPresentation = true
        search.searchBar.placeholder = ""
        search.searchResultsUpdater = self
        return search
    }()
    
    
    init?(coder: NSCoder, presenter: NFTProvidersPresenterProtocol, mode: NFTProviders.Mode, configureAccountAlertDelegate: ConfigureAccountAlertDelegate?) {
        self.presenter = presenter
        self.mode = mode
        super.init(coder: coder)
        self.presenter?.view = self
        self.configureAccountAlertDelegate = configureAccountAlertDelegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        view = View(action: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        didInitiate(action: NFTProviders.Action.fetch(forceReload: true))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !SettingsHelper.isIdentityConfigured() {
            configureAccountAlertDelegate?.showConfigureAccountAlert()
        }
    }
}


extension NFTProvidersViewController {
    
    private func setup() {
        navigationItem.rightBarButtonItem = addProviderTBarButton

        switch mode {
        case .marketplace:
            navigationItem.leftBarButtonItem = nil
        case .wallet(_, let title):
            self.title = title
            navigationItem.leftBarButtonItem = backBarButton
            navigationItem.rightBarButtonItem = nil
        case .tokens(_, let title):
            self.title = title
            navigationItem.leftBarButtonItem = backBarButton
            navigationItem.rightBarButtonItem = nil
        }
    }
}


extension NFTProvidersViewController: NFTProvidersDisplayLogic {
    
    func display(state: NFTProviders.ViewControllerState) {
        DispatchQueue.main.async { [weak self] in
            self?.resolveDisplay(state: state)
        }
    }
    
    func resolveDisplay(state: NFTProviders.ViewControllerState) {
    
        switch state {
        case .loading:
            customView.showLoadingView()
        case .error:
            customView.showErrorView()
        case .emptyResult:
            customView.showEmptyView()
        case .result(let items):
            customView.showResults(items: items, mode: mode)
        }
    }
}

extension NFTProvidersViewController: ActionProtocol {
    
    func didInitiate(action: ActionTypeProtocol) {
        guard let action = action as? NFTProviders.Action else { return }

        switch action {
        case .openMarketplace(let model):
            presenter?.open(mode: .wallet(model.wallets, title: model.name))
        case .openWallet(let model):
            presenter?.open(mode: .tokens(model.tokens, title: model.name))
        case .openToken(let model):
            if let url = URL(string: model.model.nftPage) {
                UIApplication.shared.open(url)
            }
        case .delete(let model):
            presenter?.delete(model: model)
        case .fetch(let forceReload):
            presenter?.fetch(for: mode, forceReload: forceReload)
        case .search(let text):
            if text.isEmpty {
                presenter?.fetch(for: mode, forceReload: true)
            } else {
                presenter?.search(for: mode, wiht: text.lowercased())
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension NFTProvidersViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        //fetch(isReset: true, text: text)
    }
}



extension NFTProvidersViewController {
    
    @objc func addProviderTapped() {
        presenter?.addProvider()
    }
    
    @objc func searchTapped() {
        navigationItem.searchController = searchController
    }
    
    @objc func backTapped() {
        presenter?.pop()
    }
}
