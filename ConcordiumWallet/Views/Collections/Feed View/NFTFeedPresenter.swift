//
//  NFTFeedPresenter.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

// Presenter -> Coordinator
protocol NFTFeedPresenterDelegate: AnyObject {
    func search()
    func addProvider()
    func open()
}


// View -> Presenter
protocol NFTFeedPresenterProtocol {
    
    func addProvider()
    func search()
    func open() 
}


class NFTFeedPresenter: NFTFeedPresenterProtocol {
    
    weak var delegate: NFTFeedPresenterDelegate?
    private var dependencyProvider: NFTFlowCoordinatorDependencyProvider
    
    
    init(dependencyProvider: NFTFlowCoordinatorDependencyProvider, delegate: NFTFeedPresenterDelegate) {
        self.dependencyProvider = dependencyProvider
        self.delegate = delegate
    }
}


extension NFTFeedPresenter {
    
   func addProvider() {
       delegate?.addProvider()
    }
    
    func search() {
        delegate?.search()
    }
    
    func open() {
    	delegate?.open()
    }
}
