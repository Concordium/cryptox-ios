//
//  BakerPoolGenerateKeyViewController.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 07/04/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit
import Combine
import SwiftUI

// MARK: View
protocol BakerPoolGenerateKeyViewProtocol: ShowAlert, Loadable {
    func bind(viewModel: BakerPoolGenerateKeyViewModel)
}

class BakerPoolGenerateKeyFactory {
    class func create(with presenter: BakerPoolGenerateKeyPresenterProtocol) -> BakerPoolGenerateKeyViewController {
        BakerPoolGenerateKeyViewController.instantiate(fromStoryboard: "Stake") {coder in
            return BakerPoolGenerateKeyViewController(coder: coder, presenter: presenter)
        }
    }
}

class BakerPoolGenerateKeyViewController: BaseViewController, BakerPoolGenerateKeyViewProtocol, Storyboarded {

	var presenter: BakerPoolGenerateKeyPresenterProtocol
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var electionKeyLabel: UILabel!
    @IBOutlet weak var electionContentLabel: UILabel!
    @IBOutlet weak var signatureKeyLabel: UILabel!
    @IBOutlet weak var signatureContentLabel: UILabel!
    @IBOutlet weak var aggregationKeyLabel: UILabel!
    @IBOutlet weak var aggregationContentLabel: UILabel!
    
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var dataContainerView: UIView!
    
    @IBOutlet weak var infoContainerView: UIView!
    @IBOutlet weak var infoBakerLabel: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    
    init?(coder: NSCoder, presenter: BakerPoolGenerateKeyPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dataContainerView.layer.cornerRadius = 24
        dataContainerView.layer.borderWidth = 1
        dataContainerView.layer.borderColor = UIColor(Color(red: 0.07, green: 0.38, blue: 1).opacity(0.12)).cgColor
        infoContainerView.layer.borderWidth = 1
        infoContainerView.layer.borderColor = UIColor.greenSecondary.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.view = self
        presenter.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ico_close"),
            style: .plain,
            target: self,
            action: #selector(pressedClose)
        )
        
        infoLabel.font = Fonts.body
        electionKeyLabel.font = Fonts.info
        electionContentLabel.font = Fonts.mono
        signatureKeyLabel.font = Fonts.info
        signatureContentLabel.font = Fonts.mono
        aggregationKeyLabel.font = Fonts.info
        aggregationContentLabel.font = Fonts.mono
        
        infoBakerLabel.text = "baking.generatekeys.info.subtitle".localized
    }
    
    func bind(viewModel: BakerPoolGenerateKeyViewModel) {
        viewModel.$title
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
        
        viewModel.$info
            .assign(to: \.text, on: infoLabel)
            .store(in: &cancellables)
        
        viewModel.$electionKeyTitle
            .assign(to: \.text, on: electionKeyLabel)
            .store(in: &cancellables)
        
        viewModel.$electionKeyContent
            .assign(to: \.text, on: electionContentLabel)
            .store(in: &cancellables)
        
        viewModel.$signatureKeyTitle
            .assign(to: \.text, on: signatureKeyLabel)
            .store(in: &cancellables)
        
        viewModel.$signatureKeyContent
            .assign(to: \.text, on: signatureContentLabel)
            .store(in: &cancellables)
        
        viewModel.$aggregationKeyTitle
            .assign(to: \.text, on: aggregationKeyLabel)
            .store(in: &cancellables)
        
        viewModel.$aggregationKeyContent
            .assign(to: \.text, on: aggregationContentLabel)
            .store(in: &cancellables)
    }

    @IBAction func pressedExport(_ sender: UIButton) {
        presenter.handleExport()
    }
    
    @objc func pressedClose() {
        presenter.handleClose()
    }
}
