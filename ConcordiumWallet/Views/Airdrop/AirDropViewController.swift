//
//  AirDropViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

class AirDropViewController: UIViewController, SpecificViewForController {
    typealias View = AirDropContainerView
    
    var accs: [AccountDataType]?
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider?
    private var selectedAcc: AccountDataType?
	let model: Model.Flyer
    
    init(model: Model.Flyer, accs: [AccountDataType]) {
        self.model = model
        self.accs = accs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = View.instantie(delegate: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedAcc = self.accs?.first
        customView.update(with: model)
        customView.showConnectView()
    }
}


// MARK: – Network
extension AirDropViewController {
    
    func connectAction() {
        guard let airdropId = Int(model.airdropId) else { return }
        guard let wallet = selectedAcc?.address else { return }
        
        Task { [weak self] in
            do {
                let model = try await AIRDROPService.perform(with: airdropId, wallet: wallet, urlString: model.apiUrl)
                //self?.showSuccessAlert(with: model)
                self?.customView.showResultView(status: model.success, message: model.message)
            } catch _ {
                //self?.showFailureAlert()
                self?.customView.showResultView(status: false, message: "airdrop.error.message".localized)
            }
        }
    }
}


// MARK: – Alert
extension AirDropViewController: ShowToast {
    private func showFailureAlert() {
        showToast1(withMessage: "airdrop.success.error".localized, backgroundColor: UIColor.pinkyMain, time: 3)
    }
    
    private func showSuccessAlert(with model:  Model.Airdrop) {
        showToast1(withMessage: "airdrop.success.title".localized, backgroundColor: UIColor.greenSecondary, time: 3)
    }
}


// MARK: – AirDropContainerViewDelegate
extension AirDropViewController: AirDropContainerViewDelegate {
    func cancel(from: AirDropContainerView) {
        dismiss(animated: true)
    }
    
    func connect(from: AirDropContainerView) {
        customView.showWallets(items: accs ?? [])
    }
    
    func perform(from: AirDropContainerView) {
        connectAction()
    }
    
    func didSelect(from: AirDropContainerView, model: AccountDataType) {
        selectedAcc = model
    }
    
    func done(from: AirDropContainerView) {
        dismiss(animated: true)
    }
}
