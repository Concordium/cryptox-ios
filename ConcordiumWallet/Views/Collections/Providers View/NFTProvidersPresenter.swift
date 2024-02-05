//
//  NFTProvidersPresenter.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import UIKit

// Presenter -> Coordinator
protocol NFTProvidersPresenterDelegate: AnyObject {
    func search()
    func addProvider()
    func open(mode: NFTProviders.Mode)
    func pop()
}

// View -> Presenter
protocol NFTProvidersPresenterProtocol {
    var view: NFTProvidersDisplayLogic? { get set }
    
    func addProvider()
    func search()
    func open(mode: NFTProviders.Mode)
    func pop()
    func fetch(for mode: NFTProviders.Mode, forceReload: Bool)
    func search(for mode: NFTProviders.Mode, wiht text: String)
    func delete(model: NFTMarketplaceViewModel)
}



class NFTProvidersPresenter: NFTProvidersPresenterProtocol {
    
    weak var delegate: NFTProvidersPresenterDelegate?
    private var dependencyProvider: NFTFlowCoordinatorDependencyProvider
    weak var view: NFTProvidersDisplayLogic?
    
    private var marketplaces: [NFTMarketplaceViewModel] = []
    
    init(dependencyProvider: NFTFlowCoordinatorDependencyProvider, delegate: NFTProvidersPresenterDelegate) {
        self.dependencyProvider = dependencyProvider
        self.delegate = delegate
    }
}

// MARK: – NFTProvidersPresenterProtocol
extension NFTProvidersPresenter {
    
    func addProvider() {
        delegate?.addProvider()
     }
     
     func search() {
         delegate?.search()
     }
     
    func open(mode: NFTProviders.Mode) {
         delegate?.open(mode: mode)
     }
    
    func pop() {
        delegate?.pop()
    }
    
    func fetch(for mode: NFTProviders.Mode, forceReload: Bool) {
        view?.display(state: .loading)
        switch mode {
        case .marketplace:
            if forceReload {
                marketplaces.removeAll()
            }
            
            if marketplaces.isEmpty {
                marketplaces.removeAll()
                fetchMarketplaces()
            } else {
                let items = self.make(with: marketplaces)
                let state: NFTProviders.ViewControllerState = marketplaces.isEmpty ? .emptyResult : .result(items)
                view?.display(state: state)
            }
        case .wallet(let places, _):
            let items = self.make(with: places)
            let state: NFTProviders.ViewControllerState = .result(items)
            view?.display(state: state)
        case .tokens(let tokens, _):
            let items = self.make(with: tokens)
            let state: NFTProviders.ViewControllerState = .result(items)
            view?.display(state: state)
        }
    }
    
    func search(for mode: NFTProviders.Mode, wiht text: String) {
        switch mode {
        case .tokens(let tokens, _):
            let filtered = tokens.filter( { $0.nftName.lowercased().hasPrefix(text) })
            let items = self.make(with: filtered)
            let state: NFTProviders.ViewControllerState = .result(items)
            view?.display(state: state)
        default:
            break
        }
    }

    
    func delete(model: NFTMarketplaceViewModel) {
        marketplaces = marketplaces.filter({ $0.uuid != model.uuid })
        NFTRepository.MarketPlace.remove(by: model.uuid)
        let items = self.make(with: marketplaces)
        let state: NFTProviders.ViewControllerState = marketplaces.isEmpty ? .emptyResult : .result(items)
        view?.display(state: state)
        fetch(for: .marketplace, forceReload: true)
    }
}

extension NFTProvidersPresenter {
        
    func fetchMarketplaces() {
        view?.display(state: .loading)
        let wallets = dependencyProvider.nftService().wallets
        Task { [weak self] in
            do {
                let places = try await dependencyProvider.nftService().fetch(wallets: wallets)
                self?.marketplaces = places
                let items = self?.make(with: places) ?? []
                let state: NFTProviders.ViewControllerState = places.isEmpty ? .emptyResult : .result(items)
                view?.display(state: state)
            } catch {
                view?.display(state: .error)
            }
        }
    }
}

// MARK: – WRAPer
extension NFTProvidersPresenter {
    
    private func make(with tokens: [Model.NFT.Token]) -> [NFTProviders.Section] {
        var items: [NFTProviders.Section.Item] = tokens.map({ model in .token(NFTTokenViewModel(with: model))})
        if tokens.isEmpty {
            items = [.noItems]
        }
        return [NFTProviders.Section(header: .header,
                                  items: items
                                 )]
    }
    
    private func make(with items: [NFTMarketplaceViewModel]) -> [NFTProviders.Section] {
        return [NFTProviders.Section(header: .header,
                                     items: items.map({ .marketplace($0)})
                                 )]
    }
    
    private func make(with items: [NFTWalletViewModel]) -> [NFTProviders.Section] {
        return [NFTProviders.Section(header: .header,
                                     items: items.map({ .wallet($0)})
                                 )]
    }
}
