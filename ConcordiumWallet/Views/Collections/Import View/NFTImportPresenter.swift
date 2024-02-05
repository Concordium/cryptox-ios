//
//  NFTImportPresenter.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import Combine

// Presenter -> Coordinator
protocol NFTImportPresenterDelegate: AnyObject {
    func dissmiss()
    func marketplaceWasAded()
}

// View -> Presenter
protocol NFTImportPresenterProtocol {
    var view: ANFTImportDisplayLogic? { get set }
    func fetch(with address: String, and name: String)
}


class NFTImportPresenter: NFTImportPresenterProtocol {

    weak var delegate: NFTImportPresenterDelegate?
    weak var view: ANFTImportDisplayLogic?
    private var dependencyProvider: NFTFlowCoordinatorDependencyProvider

    private var cancellables = [AnyCancellable]()

    init(dependencyProvider: NFTFlowCoordinatorDependencyProvider, delegate: NFTImportPresenterDelegate) {
        self.dependencyProvider = dependencyProvider
        self.delegate = delegate
    }
}


extension NFTImportPresenter {
    
    func fetch(with address: String, and name: String) {
        view?.display(state: .loading)
        let wallets = dependencyProvider.nftService().fetchAccounts()
        Task { [weak self] in
            do {
                let tokens = try await dependencyProvider.nftService().fetchTokens(from: address, by: wallets)
                let items = self?.make(with: tokens) ?? []
                let state: NFTImport.ViewControllerState = tokens.isEmpty ? .emptyResult : .result(items)
                NFTRepository.MarketPlace.store(host: address, name: name)
                view?.display(state: state)
                delegate?.marketplaceWasAded()
            } catch {
                view?.display(state: .error)
            }
        }
    }
}


extension NFTImportPresenter {
    
    private func make(with tokens: [Model.NFT.Token]) -> [NFTImport.Section] {
        return [NFTImport.Section(header: .noHeader,
                                  items: tokens.map({ model in .item(NFTTokenViewModel(with: model))})
                                 )]
    }
}
