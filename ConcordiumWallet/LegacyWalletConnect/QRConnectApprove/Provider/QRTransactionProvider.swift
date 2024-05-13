//
//  QRTransactionProvider.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 15.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import SwiftUI
import Combine
import Base58Swift



protocol QRTransactionProviderDelegate: SendFundConfirmationPresenterDelegate {
    func dismiss( compleation: @escaping () -> ())
    func present(_ presenter: RequestPasswordPresenter)
    func present(method: String, hex: String)
    //func present(_ presenter: RequestPasswordPresenter)
    func fetched(energy: Int, fee: Int, cost: Int, nrgCCDAmount: Int)
    func presentError(title: String, subtitle: String)
}


protocol QRTransactionProviderProtocol {
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider? { get set }

    var nrgLimit: Int { get set }
    
    var delegate: QRTransactionProviderDelegate? { get set }
    
    func connect(connectionData: QRDataResponse?, accs: [AccountDataType]?)
    func approveTransaction(with model: Model.Transaction)
    func cancelTransaction()
}


class QRTransactionProvider: QRTransactionProviderProtocol {
    
    @ObservedObject var service = WebSocketService()
    
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider?
    private var cancellables = [AnyCancellable]()
    private var fee: Int = 0
    private var energy: Int = 0
    private var cost: Int = 0
    var nrgLimit: Int = 100501
    
    weak var delegate: QRTransactionProviderDelegate?
    
    func connect(connectionData: QRDataResponse?, accs: [AccountDataType]?) {
        service.dependencyProvider = dependencyProvider
        service.connectionData = connectionData
        service.connect(url: connectionData?.ws_conn ?? "")
        service.accs =  accs
        fetchEnergy()
    }
    
    func approveTransaction(with model: Model.Transaction) {
        accept(with: model, energy: energy)
    }
    
    func cancelTransaction() {
        service.sendPaymentRejectionMessage()
        delegate?.dismiss { }
    }
}


// MARK: - accept

extension QRTransactionProvider {
    
    
    private func fetchEnergy() {
        dependencyProvider?.transactionsService().getTransferCost(transferType: .simpleTransfer, costParameters: []).sink(receiveError: { (error) in
            LegacyLogger.error(error)
            //self?.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
        }, receiveValue: { [weak self] (value) in
            let _cost = Int(value.cost) ?? 0
            let _fee = (_cost)
            let _energy = value.energy
            self?.fee = _fee
            self?.energy = _energy
            self?.cost = _cost
            let nrgCCDAmount = self?.getNrgCCDAmount(nrgLimit: self?.nrgLimit ?? 0) ?? 0
            self?.delegate?.fetched(energy: _energy + 100000, fee: _fee, cost: _cost, nrgCCDAmount: nrgCCDAmount)
        }).store(in: &cancellables)
    }
    
    private func accept(with model: Model.Transaction, energy: Int) {
        
        guard let dependencyProvider = dependencyProvider else {
            delegate?.sendFundFailed(error: MobileWalletError.invalidArgument)
            return
        }
        
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = .transferUpdate
        transfer.fromAddress = model.data.from
        transfer.from = model.data.from //??
        transfer.cost = String(cost)
        transfer.expiry = Date.expiration(from: model.data.expiry)
        transfer.energy = model.data.nrg_limit
        transfer.amount = model.data.amount
        transfer.toAddress = model.data.from
        transfer.receiveName = model.data.contract_name + "." + model.data.contract_method
        transfer.contractAddressObject = ContractAddressObject()
        transfer.contractAddressObject.index = model.data.contract_address.index
        transfer.contractAddressObject.subindex = model.data.contract_address.sub_index
        
        
        /* "_93":
        let contractParams = model.data.contract_params
        let origUint64 = Int(contractParams[0].param_value)
        let origUint642 = Int(contractParams[2].param_value)
        let url = contractParams[3].param_value
        
        let paramTokenId = String(origUint64!.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")
        let paramValue = "00" //Data("00".utf8).hexEncodedString()
        let paramRoyaltyPercent = String(origUint642!.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")
        let paramUrl = url.count.data.hexEncodedString() + Data(url.utf8).hexEncodedString()
        
        transfer.params = paramTokenId + paramValue + paramRoyaltyPercent + paramUrl*/
        
//        let builder = QRTransactionParamsBuilder()
//        transfer.params = builder.build(from: model,
//                                        index: model.data.contract_address.index )
            
        transfer.params = model.data.serialized_params
        //guard let accounts = self.dependencyProvider?.storageManager().getAccounts() else { return }
        
        let account = self.dependencyProvider?.storageManager().getAccounts().first{ $0.address == model.data.from }
        guard let account = account else { return }
        
        // TransferUpdate Contract Address
        let contractAddress = ContractAddress1(index: model.data.contract_address.index,
                                               subindex: model.data.contract_address.sub_index)
        
        
        // CHECK
        let totalBalance = account.forecastBalance //+ account.forecastEncryptedBalance
        let amount = Int(model.data.amount) ?? 0
        let nrgCCDAmount = getNrgCCDAmount(nrgLimit: model.data.nrg_limit)
        
        let ccdAmount =  GTU(intValue: amount)
        let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdTotalBalance = GTU(intValue: totalBalance)
        
        if ccdTotalBalance.intValue  < ccdTotalAmount.intValue {
            // stop operation and show alert
            let opperationCost = ccdTotalAmount
            let subtitle = String(format: "qrtransactiondata.error.subtitle".localized, opperationCost.displayValue())
            delegate?.presentError(title: "qrtransactiondata.error.title".localized, subtitle: subtitle)
        } else {
            let action = transfer.receiveName
            //model.data.contract_title != nil ? model.data.contract_name + "." + model.data.contract_method : nil
            performTransfer(transfer, contractMethod: model.data.contract_method, from: account, action: action, to: contractAddress, with: dependencyProvider)
        }
    }
    
    
    private func performTransfer(_ transfer: TransferDataType, contractMethod: String, from account: AccountDataType, action: String?, to contractAddress: ContractAddress1, with dependencyProvider: AccountsFlowCoordinatorDependencyProvider) {
        
        dependencyProvider.transactionsService()
            .performTransferUpdate(transfer, from: account, contractAddress: contractAddress, requestPasswordDelegate: self)
        //.performTransfer(transfer, from: fromAccount, requestPasswordDelegate: self)
        //              .showLoadingIndicator(in: self.view)
//            .map(\.0)
            .tryMap(dependencyProvider.storageManager().storeTransfer)
            .sink(receiveError: { [weak self] error in
                //                    if case NetworkError.serverError = error {
                //                        Logger.error(error)
                //                        self?.delegate?.sendFundFailed(error: error)
                //                    } else if case GeneralError.userCancelled = error {
                self?.delegate?.sendFundFailed(error: MobileWalletError.invalidArgument)
                return
                //                    } else {
                //                        self?.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
                //                    }
            }, receiveValue: { [weak self] in
                //                  Logger.debug($0)
                // ------- self.delegate?.sendFundSubmitted(transfer: $0, recipient: self.recipient!)
                self?.service.sendPaymentMessage(hash: $0.submissionId ?? "", action: action)
                let hex = $0.submissionId ?? ""
                let method = contractMethod.replacingOccurrences(of: "_", with: " ")
                
                self?.delegate?.present(method: method, hex: hex)
                //self?.delegate?.dismiss { }
            }).store(in: &cancellables)
    }
}


// MARK: - RequestPasswordDelegate

extension QRTransactionProvider: RequestPasswordDelegate {
    
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
                    self?.delegate?.dismiss {
                        promise(result)
                    }
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
    
    private func show(_ presenter: RequestPasswordPresenter) {
        delegate?.present(presenter)
    }
}



extension QRTransactionProvider {
    
    private func getNrgCCDAmount(nrgLimit: Int) -> Int {
        
        let _cost = Float(cost)
        let _energy = Float(energy)
        let _nrgLimit = Float(nrgLimit)
        
        let nrgCCDAmount = Float(_nrgLimit * (_cost / _energy) / 1000000.0)
        //
        return Int(ceil(nrgCCDAmount))
    }
}
