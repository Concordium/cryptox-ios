//
//  NFTFeedViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class NFTFeedFactory {
    class func create(with presenter: NFTFeedPresenterProtocol) -> NFTFeedViewController {
        NFTFeedViewController.instantiate(fromStoryboard: "Collections") { coder in
            return NFTFeedViewController(coder: coder, presenter: presenter)
        }
    }
}


class NFTFeedViewController: BaseViewController, Storyboarded {

    var presenter: NFTFeedPresenterProtocol?
    
    private lazy var searchBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "search")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.searchTapped))
    }()
    
    private lazy var addProviderTBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "add")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.addProviderTapped))
    }()
    
    init?(coder: NSCoder, presenter: NFTFeedPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = searchBarButton
        navigationItem.rightBarButtonItem = addProviderTBarButton
    }
}


extension NFTFeedViewController {
    
    @objc func addProviderTapped() {
        presenter?.addProvider()
    }
    
    @objc func searchTapped() {
        presenter?.search()
    }
    
    @objc func openTapped() {
        presenter?.open()
    }
}
