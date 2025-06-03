//
//  QRTransactionViewController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 14.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


protocol QRTransactionDisplayLogic: AnyObject { }


class QRTransactionViewController: UIViewController, SpecificViewForController, ShowToast {
    typealias View = QRTransactionView

    private let model: Model.Transaction
    private var provider: QRTransactionProviderProtocol
    var connectionData: QRDataResponse?
    var accs: [AccountDataType]?
    
    private var isConnectTapped: Bool = false
    
    lazy var dismissBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "ico_close")
        return UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.closeButtonTapped))
    }()
    
    init(model: Model.Transaction, provider: QRTransactionProviderProtocol) {
        self.model = model
        self.provider = provider
        self.provider.nrgLimit = model.data.nrg_limit
        super.init(nibName: nil, bundle: nil)
        self.provider.delegate = self
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        view = View(action: self)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    

    @objc private func closeButtonTapped() {
        provider.cancelTransaction()
        dismiss(animated: true)
    }
    
    private func setupUI() {
        navigationItem.leftBarButtonItem = dismissBarButton
        
        provider.connect(connectionData: connectionData, accs: accs)
        customView.show(model: model, accs: accs, connectionData: connectionData)
            //provider.approveTransaction(with: mode)
    }
}


// MARK: – Actions
extension QRTransactionViewController: ActionProtocol {
    func didInitiate(action: ActionTypeProtocol) {
        guard let action = action as? QRTransaction.Action else { return }
        
        switch action {
            case .accept:
                accept()
            case .cancel:
                provider.cancelTransaction()
                dismiss(animated: true)
            case .edit: break
            case .showData: break
        }
    }
}


// MARK: – Display logic

extension QRTransactionViewController: QRTransactionDisplayLogic {
    
}


// MARK: – UTILs

extension QRTransactionViewController {
    
    private func accept() {
        isConnectTapped = true
        provider.approveTransaction(with: model)
    }
}


// MARK: – QRTransactionProviderDelegate

extension QRTransactionViewController: QRTransactionProviderDelegate {
    
    func presentError(title: String, subtitle: String) {
        
        showToast1(withMessage: "\(title)\n\(subtitle)", backgroundColor: UIColor.pinkyMain, time: 3)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.dismiss(animated: true)
//        }
    }
    
    
    func fetched(energy: Int, fee: Int, cost: Int, nrgCCDAmount: Int) {
        customView.shot(model: model, energy: energy, fee: fee, cost: cost, nrgCCDAmount: nrgCCDAmount)
        
        
        let account = provider.dependencyProvider?.storageManager().getAccounts().first{ $0.address == model.data.from }
        guard let account = account else { return }
                
        // CHECK
        let totalBalance = account.forecastBalance //+ account.forecastEncryptedBalance
        let amount = Int(model.data.amount) ?? 0
    
        
        let ccdAmount =  GTU(intValue: amount)
        let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdTotalBalance = GTU(intValue: totalBalance)
        
        if ccdTotalBalance.intValue  < ccdTotalAmount.intValue {
            let subtitle = String(format: "qrtransactiondata.error.subtitle".localized, ccdTotalAmount.displayValue())
            presentError(title: "qrtransactiondata.error.title".localized, subtitle: subtitle)
        }
    }
    
    
    func sendFundSubmitted(transfer: TransferDataType, recipient: RecipientDataType) {
        navigationController?.dismiss(animated: true)
    }
    
    func sendFundFailed(error: Error) {
        navigationController?.dismiss(animated: true)
    }
   
    func dismiss(compleation: @escaping () -> ()) {
        navigationController?.dismiss(animated: true) {
            compleation()
        }
    }
    
    func present(_ presenter: RequestPasswordPresenter) {
        guard isConnectTapped else { return }
        let vc = EnterPasswordFactory.create(with: presenter)
        let nc = CXNavigationController()
        nc.modalPresentationStyle = .fullScreen
        nc.viewControllers = [vc]
        navigationController?.present(nc, animated: true)
    }
    
    func present(method: String, hex: String) {
        DispatchQueue.main.async {
            let controller = QRTransactionDataViewController(method: method, hex: hex) { [weak self] in
                self?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
            self.present(controller, animated: true, completion: nil)
        }
    }
}
