//
//  NFTImportViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTImportFactory {
    class func create(with presenter: NFTImportPresenterProtocol) -> NFTImportViewController {
        NFTImportViewController.instantiate(fromStoryboard: "Collections") { coder in
            return NFTImportViewController(coder: coder, presenter: presenter)
        }
    }
}

protocol ANFTImportDisplayLogic: AnyObject {
    func display(state: NFTImport.ViewControllerState)
}


class NFTImportViewController: BaseViewController, Storyboarded, SpecificViewForController {
    typealias View = NFTImportView

    private var state: NFTImport.ViewControllerState = .inputData
    
    var presenter: NFTImportPresenterProtocol?

    init?(coder: NSCoder, presenter: NFTImportPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
        self.presenter?.view = self

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = View(action: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "nft.import.title".localized
        customView.showInputView()
        
        display(state: state)

    }
}


extension NFTImportViewController: ANFTImportDisplayLogic {
    
    func display(state: NFTImport.ViewControllerState) {
        DispatchQueue.main.async { [weak self] in
            self?.resolveDisplay(state: state)
        }
    }
    
    func resolveDisplay(state: NFTImport.ViewControllerState) {
        self.state = state
        switch state {
        case .inputData:
            customView.showInputView()
        case .loading:
            customView.showLoadingView()
        case .error:
            customView.showErrorView()
        case .emptyResult:
            customView.showEmptyView()
        case .result(let items):
            customView.showResults(items: items)
        }
    }
}


extension NFTImportViewController: ActionProtocol {
    
    func didInitiate(action: ActionTypeProtocol) {
        guard let action = action as? NFTImport.Action else { return }
        switch action {
        case .open(let model):
            if let url = URL(string: model.model.nftPage) {
                UIApplication.shared.open(url)
            }
            
        case .fetch(let address, let name):
            title = name
            if address.contains("https://") {
                presenter?.fetch(with: address, and: name)
            } else {
                presenter?.fetch(with: "https://" + address, and: name)
            }
        }
    }
}
