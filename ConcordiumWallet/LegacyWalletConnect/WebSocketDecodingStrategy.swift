//
//  WebSocketDecodingStrategy.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 13.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation


enum WebSocketDecodingState {
    case error(Error?)
    case string(String)
    case sendWallets
    case nft(CreateNFTResponce?)
    case transaction(Model.Transaction)
    case data(Data)
    case simpleTransfer(SimpleTransferObject)
}


protocol WebSocketDecodingStrategyDeledate: AnyObject {
    
    func didDecoded(state: WebSocketDecodingState)
}



class WebSocketDecodingStrategy {
    
    weak var delegate: WebSocketDecodingStrategyDeledate?
    
    
    func decode(from result: Result<URLSessionWebSocketTask.Message, Error>) {
        
        switch result {
        case .success(let message):
            decode(message)
        case .failure(let error):
            delegate?.didDecoded(state: .error(error))
        }
    }
}


// MARK: –
extension WebSocketDecodingStrategy {
    
    private func decode(_ message: URLSessionWebSocketTask.Message) {
        
        switch message {
        case .string(let string):
            decode(string)
            
        case .data(let data):
            decode(data)
            
        @unknown default:
            break
        }
    }
}


struct QRConnectMessage: Codable {
    enum MessageType: String, Codable {
        case transaction = "Transaction"
        case simpleTransfer = "SimpleTransfer"
        case accountInfo = "AccountInfo"
    }
    
    let message_type: MessageType
}

struct SimpleTransferData: Codable {
    let amount: String
    let expiry: String
    let from: String
    let nonce: String
    let nrg_limit: String
    let serialized_params: String
    let to: String
}

struct SimpleTransferObject: Codable {
    let data: SimpleTransferData
    let message_type: QRConnectMessage.MessageType
}

// MARK: –
extension WebSocketDecodingStrategy {
    private func decode(_ string: String) {
        delegate?.didDecoded(state: .string(string))
        
        if let stringData = string.components(separatedBy: "proxy#").last,
            let data = stringData.data(using: .utf8) {
            do {
                let message = try JSONDecoder().decode(QRConnectMessage.self, from: data)
                switch message.message_type {
                    case .simpleTransfer:
                        do {
                            let simpleTransferObject = try JSONDecoder().decode(SimpleTransferObject.self, from: data)
                            delegate?.didDecoded(state: .simpleTransfer(simpleTransferObject))
                        } catch {
                            delegate?.didDecoded(state: .error(nil))
                        }
                    case .transaction:
                        do {
                            let model = try JSONDecoder().decode(Model.Transaction.self, from: data)
                            delegate?.didDecoded(state: .transaction(model))
                        } catch {
                            delegate?.didDecoded(state: .error(nil))
                        }
                    case .accountInfo:
                        parseString(string)
                }
            } catch {
                delegate?.didDecoded(state: .error(nil))
            }
            
        }
        
        /// Check .nft type donno know where it is using  or using it at all
        func parseString(_ string: String) {
            switch string {
             case let str where str.contains("AccountInfo"):
                delegate?.didDecoded(state: .sendWallets)
                fallthrough
            
            case let str where  str.contains("contract_method"):
                
                if let stringData = str.components(separatedBy: "proxy#").last, let data = stringData.data(using: .utf8) {
                    let decoder: JSONDecoder = JSONDecoder()
                    do {
                        let model = try decoder.decode(Model.Transaction.self, from: data)
                        delegate?.didDecoded(state: .transaction(model))
                    } catch {
                        delegate?.didDecoded(state: .error(nil))
                    }
                } else {
                    delegate?.didDecoded(state: .error(nil))
                }

                
            case let str where str.contains("from"):
                
                //let data: Data? = str.data(using: .utf8)
                let srvData = try? CreateNFTResponce.decode(from: str.components(separatedBy: "proxy#").last!.data(using: .utf8) ?? Data())
                delegate?.didDecoded(state: .nft(srvData))
            default:
                break
            }
        }
    }
    
    private func decode(_ data: Data) {
        delegate?.didDecoded(state: .data(data))
    }
}
