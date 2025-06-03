//
//  WebSocketService.swift
//  ConcordiumWallet
//
//  Created by Alex Kudlak on 2021-07-15.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation
import Combine
import UIKit
import BigInt

class WebSocketService : ObservableObject {

    private let networkId = ApiConstants.networkId
    private let urlSession = URLSession(configuration: .default)
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var decodingStrategy: WebSocketDecodingStrategy = {
        let strategy = WebSocketDecodingStrategy()
        strategy.delegate = self
        return strategy
    }()
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider?
    var connectionData: QRDataResponse?

    let didChange = PassthroughSubject<Void, Never>()
    @Published var str: String = ""

    private var cancellable: AnyCancellable? = nil
    var accs: [AccountDataType]?

    var result: String = "" {
        didSet {
            didChange.send()
        }
    }

    init() {
        cancellable = AnyCancellable($str
                                        .debounce(for: 0.5, scheduler: DispatchQueue.main)
                                        .removeDuplicates()
                                        .assign(to: \.result, on: self))
    }

    func connect(url: String) {
        
        if let taskUrl = webSocketTask?.originalRequest?.url.toString(), taskUrl == url {
            return
        }
        
        let baseURL = URL(string: url)!

        stop()
        webSocketTask = urlSession.webSocketTask(with: baseURL)
        webSocketTask?.resume()

        receiveMessage()
    }

    private func sendPing() {
        webSocketTask?.sendPing { (error) in
            if let error = error {
                print("Sending PING failed: \(error)")
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.sendPing()
            }
        }
    }

    func stop() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func sendWallet() {
        var wallets = [[String : Any]]()
        DispatchQueue.main.async { [self] in
            for acc in accs! {
                let wallet = ["address": acc.address, "balance": acc.finalizedBalance] as [String : Any]
                wallets.append(wallet)
            }

            let jsonObject = [
                "data": wallets,
                "message_type": "AccountInfoResponse",
                "network_id": networkId,
                "originator": "CryptoX Wallet iOS app",
                "user_status": ""
            ] as [String : Any]

            let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed))!


            let message = URLSessionWebSocketTask.Message.data(data)
            webSocketTask?.send(message) { [weak self]  error in
                if let error = error {
                    print("WebSocket couldn’t send message because: \(error)")
                }
                self?.log(data)
            }
        }
    }

    func sendMessage() {
        let jsonObject = [
            "data":"ConnectionAcceptedNotification",
            "message_type":"ConnectionAcceptNotify",
            "network_id": networkId,
            "originator":"CryptoX Wallet iOS app",
            "user_status":"UserAccepted"
        ]

        let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed))!


        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
            self?.log(data)
        }
    }

    func sendPaymentMessage(_ hash: String) { self.sendPaymentMessage(hash: hash) }
    func sendPaymentMessage(hash: String, action: String? = nil)
    {
        var jsonData: [String : Any] =  [
            "tx_hash": hash,
            "tx_status": "Accepted"
        ]
        
        if let action = action {
            jsonData["action"] = action
        }

        let jsonObject = [
            "data": jsonData,
            "message_type":"SimpleTransferResponse",
            "network_id": networkId,
            "originator":"CryptoX Wallet iOS app",
            "user_status":""
        ] as [String : Any]
        
        let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed))!


        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
            self?.log(data)
        }
    }

    func sendRejectionMessage()
    {
        let jsonObject = [
            "data":"ConnectionAcceptedNotification",
            "message_type":"ConnectionAcceptNotify",
            "network_id": networkId,
            "originator":"CryptoX Wallet iOS app",
            "user_status":"UserRejected"
        ]

        let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed))!


        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
            self?.log(data)
            self?.stop()
        }
    }

    func sendPaymentRejectionMessage(){
        let jsonObject = [
            "data": [
                "tx_hash": "",
                "tx_status": "Rejected"
            ],
            "message_type":"SimpleTransferReponse",
            "network_id": networkId,
            "originator":"CryptoX Wallet iOS app",
            "user_status":""
        ] as [String : Any]

        let data = (try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed))!


        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
            self?.log(data)
            self?.stop()
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive {[weak self] result in
            self?.decodingStrategy.decode(from: result)
        }
    }
}


extension WebSocketService: WebSocketDecodingStrategyDeledate {
    func didDecoded(state: WebSocketDecodingState) {
        print("🦄: ← \(state)")
        switch state {
            case .simpleTransfer(let data):
                print(data)
                DispatchQueue.main.async {
                    self.showSignTransactionFlow(data)
                }
        case .error(let error):
            print("Error in receiving message: \(error?.localizedDescription ?? "" )")
        case .string(let string):
            print("Received text message: \(string)")
            receiveMessage()
        case .sendWallets:
            presentWalletConnection(connectionData: connectionData)
        case .nft(let srvData):
            DispatchQueue.main.async { [weak self] in
                if var topController = UIApplication.shared.keyWindow?.rootViewController  {
                    
                    let vc = ExternalPaymentVC.instantiate(fromStoryboard: "QRConnect") { coder in
                        return ExternalPaymentVC(coder: coder)
                    }
                    vc.dependencyProvider = self?.dependencyProvider
                    vc.connectionData = self?.connectionData
                    vc.toAddress = srvData?.data.from ?? ""
                    vc.contractAddress = srvData?.data.contract_address
                    vc.contractParams = srvData?.data.contract_params
                    vc.modalPresentationStyle = .overFullScreen
                    vc.contractMethod = .create
                    if srvData?.data.contract_method == "transfer_from" {
                        vc.contractMethod = .transferFrom
                    }
                    
                    topController.present(vc, animated: true, completion: nil)
                }
            }

        case .transaction(let model):
            presentQRTransaction(with: model, connectionData: connectionData)
        
        case .data(let data):
            print("Received binary message: \(data)")
            receiveMessage()
        }

    }
}

extension WebSocketService {
    private func showSignTransactionFlow(_ data: SimpleTransferObject) {
        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return }
        guard let dependencyProvider = dependencyProvider else { return }
        guard let account = dependencyProvider.storageManager().getAccounts().first(where: { $0.address == data.data.from }) else { return }
        
        let router = TransferTokenRouter(root: navigationController, account: account, dependencyProvider: dependencyProvider)
    
        router.showSimpleTransferConfirmFlow(data: data, onTxSuccess: sendPaymentMessage, onTxReject: sendPaymentRejectionMessage)
    }
}


extension WebSocketService {
    
    func presentWalletConnection(connectionData: QRDataResponse?) {
        
        DispatchQueue.main.async { [weak self] in
            if var topController = UIApplication.shared.keyWindow?.rootViewController  {
                let vc = ConnectionRequestVC.instantiate(fromStoryboard: "QRConnect") { coder in
                    return ConnectionRequestVC(coder: coder)
                }
                vc.accs = self?.accs
                vc.dependencyProvider = self?.dependencyProvider
                vc.connectionData = connectionData
                vc.status = .walletSelection
                vc.modalPresentationStyle = .overFullScreen
                topController.present(vc, animated: true)
            }
        }
    }
    
    
    func  presentQRTransaction(with model: Model.Transaction, connectionData: QRDataResponse?) {
        
        DispatchQueue.main.async { [weak self] in
            let account = self?.dependencyProvider?.storageManager().getAccounts().first{ $0.address == model.data.from }
            
            if let topController = UIApplication.shared.keyWindow?.rootViewController  {
                if let account = account {
                    self?.presentTransactionController(with: model, connectionData: connectionData, in: topController)
                } else {
                    self?.presentNoAccountDataAlert(with: model, in: topController)
                }
            }
        }
    }
}


extension WebSocketService {
    
    private func presentTransactionController(with model: Model.Transaction, connectionData: QRDataResponse?, in topController: UIViewController) {
        
        let provider = QRTransactionProvider()
        provider.dependencyProvider = dependencyProvider
        //provider.toAddress = modelInput.data.from
        
        let vc = QRTransactionViewController(model: model, provider: provider)
        vc.connectionData = connectionData
        vc.accs = accs
        
        let nc = CXNavigationController()
        nc.modalPresentationStyle = .fullScreen
        nc.viewControllers = [vc]
        
        topController.present(nc, animated: true, completion: nil)
        
    }
    
    private func presentNoAccountDataAlert(with model: Model.Transaction, in topController: UIViewController) {
        
        let alert = UIAlertController(
            title: "qrtransactiondata.error.noaccount.title".localized,
            message: model.data.from,
            preferredStyle: .alert
        )

        let dismissAction = UIAlertAction(
            title: "ok".localized,
            style: .cancel,
            handler: { _ in }
        )

        alert.addAction(dismissAction)
        topController.present(alert, animated: true, completion: nil)
    }
    
}



extension WebSocketService {
 
    private func log(_ data: Data) {
        let string = String(decoding: data, as: UTF8.self)
        print("🦄: → \(string)")
    }
}


struct CreateNFTResponce: Decodable {
    var data: FromData
    var message_type: String
}

struct FromData: Decodable {
    var from: String
    var contract_address: ContractAddress
    var contract_params: [ContractParams]
    var contract_method: String
}

struct ContractAddress: Decodable {
    var address: String
    var index: String
    var sub_index: String
}

struct ContractAddress1: Codable {
    let index: Int?
    let subindex: Int?
    
    init(index: Int?, subindex: Int?) {
        self.index = index
        self.subindex = subindex
    }
    
    init(index: String, subindex: String) {
        self.index = Int(index)
        self.subindex = Int(subindex)
    }
}

struct ContractParams: Decodable {
    var param_type: String
    var param_value: String
}

struct APIResponse: Codable {
    var session_id: String
    var connect_id : String

    private enum CodingKeys: String, CodingKey {
        case session_id, connect_id
    }
}

import Foundation

extension Encodable {
    func toString() -> String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func encode(with encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }

    func encodeSorted(with encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(self)
    }
}

extension Decodable {
    static func decode(with decoder: JSONDecoder = JSONDecoder(), from data: Data) throws -> Self? {
        do {
            let newdata = try decoder.decode(Self.self, from: data)
            return newdata
        } catch {
            return nil
        }
    }
    static func decodeArray(with decoder: JSONDecoder = JSONDecoder(), from data: Data) throws -> [Self]{
        do {
            let newdata = try decoder.decode([Self].self, from: data)
            return newdata
        } catch {
            return []
        }
    }
}

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}
