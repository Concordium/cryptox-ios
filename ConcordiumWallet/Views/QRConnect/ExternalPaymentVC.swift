//
//  ExternalPaymentVC.swift
//  ConcordiumWallet
//
//  Created by Alex Kudlak on 2021-08-18.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import Base58Swift

enum ContractMethod {
    case create
    case transferFrom
}

class ExternalPaymentVC: UIViewController, Storyboarded {

    @IBOutlet private weak var calcelButton: UIButton!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var transactionDataView: UIView!
    @IBOutlet private weak var feeLabel: UILabel!
    @IBOutlet private weak var totalLabel: UILabel!
    
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var redDotView: UIView!
    @IBOutlet private weak var titleActionLabel: UILabel!
    
    @ObservedObject var service = WebSocketService()
    private var cancellables = [AnyCancellable]()
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider?
    weak var delegate: (SendFundConfirmationPresenterDelegate & RequestPasswordDelegate)?
    
    var contractMethod: ContractMethod = .create
    
    var connectionData: QRDataResponse?
    var accs: [AccountDataType]?
    var toAddress = ""
    var contractAddress: ContractAddress? = nil
    var contractParams: [ContractParams]? = nil
    var fee = 0
    var energy = 0
    private var recipient: RecipientDataType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
    }
    
    private func setUI() {
        transactionDataView.layer.cornerRadius = 24
        
        calcelButton.layer.cornerRadius = 26
        connectButton.layer.cornerRadius = 26
        redDotView.layer.cornerRadius = 2.5
        
        calcelButton.layer.borderWidth = 1
        calcelButton.layer.borderColor = UIColor(red: 0.831, green: 0.839, blue: 0.863, alpha: 1).cgColor
        
        titleLabel.text = connectionData?.site.title
        descriptionLabel.text = connectionData?.site.description
        if let urlStr = connectionData?.site.icon_link, let url = URL(string: urlStr) {
            imgView.load(url: url)
        }
        
        if contractMethod == .transferFrom {
            titleActionLabel.text = "Token Transfer"
        }
        
        dependencyProvider?.transactionsService().getTransferCost(transferType: .simpleTransfer, costParameters: []).sink(receiveError: { [weak self] (error) in
            LegacyLogger.error(error)
//            self?.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
            }, receiveValue: { [weak self] (value) in
                print()
                self?.fee = (Int(value.cost) ?? 0) + 50000
                self?.energy = value.energy + 50000
                self?.feeLabel.text = GTU(intValue: (self?.energy ?? 0) * 10).displayValue() + " CCD"
                self?.totalLabel.text = GTU(intValue: (self?.energy ?? 0) * 10).displayValue() + " CCD"
//                self?.cost = GTU(intValue: (Int(value.cost) ?? 0))
//                self?.energy = value.energy
//                let feeMessage = "sendFund.feeMessage".localized + GTU(intValue: Int(value.cost) ?? 0).displayValue()
//                self?.viewModel.feeMessage = feeMessage
        }).store(in: &cancellables)
    }
    
    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func cancellAction(_ sender: UIButton) {
        service.sendPaymentRejectionMessage()
        dismiss(animated: true)
    }
    
    @IBAction func connectAction(_ sender: UIButton) {
        userTappedConfirm()
    }

    func userTappedConfirm() {
        if let dependencyProvider = dependencyProvider {
            var transfer = TransferDataTypeFactory.create()
            transfer.transferType = .transferUpdate

            transfer.amount = "0"
            transfer.fromAddress = self.dependencyProvider?.storageManager().getAccounts().first?.address ?? ""
            transfer.from = self.dependencyProvider?.storageManager().getAccounts().first?.address ?? ""
            transfer.toAddress = toAddress
            //nonce - goes later
            transfer.expiry = Date().addingTimeInterval(10 * 60)
            transfer.energy = energy


            if contractMethod == .create {

                let origUint64 = Int((contractParams?.first!.param_value)!)
                let origUint642 = Int((contractParams?.last!.param_value)!)

                let param1 = String(origUint64!.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")
                let param2 = "00"
                let param3 = String(origUint642!.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")

                transfer.params = param1 + param2 + param3
                transfer.receiveName = "inventory.create"
            } else {
                let origUint64 = Int((contractParams?.first!.param_value)!)
                let origUint641 = contractParams?[1].param_value ?? ""
                let origUint642 = contractParams?.last!.param_value ?? ""

                if var decoded1 = Data(hex: origUint641), var decoded2 = Data(hex: origUint642) {
                    decoded1.removeFirst()
                    decoded1.removeLast()
                    decoded1.removeLast()
                    decoded1.removeLast()
                    decoded1.removeLast()

                    decoded2.removeFirst()
                    decoded2.removeLast()
                    decoded2.removeLast()
                    decoded2.removeLast()
                    decoded2.removeLast()

                    let param1 = String(origUint64!.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")
                    let param2 = decoded1.hexEncodedString()
                    let param3 = decoded2.hexEncodedString()

                    transfer.params = param1 + param2 + param3
                }
                transfer.receiveName = "inventory.transfer_from"
            }

            let fromAccount = (self.dependencyProvider?.storageManager().getAccounts().first!) as! AccountDataType

            let index = Int((contractAddress?.index)!)
            let subindex = Int((contractAddress?.sub_index)!)
            let contractAddress = ContractAddress1(index: index, subindex: subindex)

            dependencyProvider.transactionsService()
                .performTransferUpdate(transfer, from: fromAccount, contractAddress: contractAddress, requestPasswordDelegate: self)
//                .showLoadingIndicator(in: self.view)
//                .map(\.0)
                .tryMap(dependencyProvider.storageManager().storeTransfer)
                .sink(receiveError: { [weak self] error in
//                    if case NetworkError.serverError = error {
//                        Logger.error(error)
//                        self?.delegate?.sendFundFailed(error: error)
//                    } else if case GeneralError.userCancelled = error {
                    self?.dismiss(animated: true)
                        return
//                    } else {
//                        self?.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
//                    }
                }, receiveValue: { [weak self] in
                    guard let self = self else {
                        self?.dismiss(animated: true)
                        return
                    }
//                    Logger.debug($0)

                    //let recipient = self.recipient
                    //self.delegate?.sendFundSubmitted(transfer: $0, recipient: recipient)
                    self.service.sendPaymentMessage(hash: $0.submissionId ?? "")
                    self.dismiss(animated: true)
                }).store(in: &cancellables)
        }
    }
}



extension ExternalPaymentVC: SendFundConfirmationPresenterDelegate {
    func sendFundSubmitted(transfer: TransferDataType, recipient: RecipientDataType) {
        self.recipient = recipient
//        showTransactionSubmitted(transfer: transfer, recipient: recipient)
        print()
    }

    func sendFundFailed(error: Error) {
//        showTransferFailed(error: error)
        print()
    }
}

extension ExternalPaymentVC: RequestPasswordDelegate {
    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
        let requestPasswordPresenter = RequestPasswordPresenter(keychain: keychain)
        var modalPasswordVCShown = false

        requestPasswordPresenter.performBiometricLogin(fallback: { [weak self] in
            self?.show(requestPasswordPresenter)
            modalPasswordVCShown = true
        })

        let cleanup: (Result<String, Error>) -> Future<String, Error> = { [weak self] result in
                    let future = Future<String, Error> { promise in
                        if modalPasswordVCShown {
                            self?.presentedViewController?.dismiss(animated: true, completion: {
                                promise(result)
                            })
                        } else {
                            promise(result)
                        }
                    }
                    return future
                }

        return requestPasswordPresenter.passwordPublisher
                .flatMap { cleanup(.success($0)) }
                .catch { cleanup(.failure($0)) }
                .eraseToAnyPublisher()
    }

    private func  show(_ presenter: RequestPasswordPresenter) {
        let vc = EnterPasswordFactory.create(with: presenter)
        let nc = CXNavigationController()
        nc.modalPresentationStyle = .fullScreen
        nc.viewControllers = [vc]
       // self.navigationController?.present(nc, animated: true)
        self.present(nc, animated: true)
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
            
            let newLength = self.count
            
            if newLength < toLength {
            
                return String(repeatElement(character, count: toLength - newLength)) + self
            
            } else {
            
                return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
            
            }
        }
}
