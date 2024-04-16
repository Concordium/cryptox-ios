//
//  SessionRequestDataType.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify

struct SessionRequestType: Codable {
    let type: TransferType
    
    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode 'type' field into TransferType.
        let typeStr = try container.decode(String.self, forKey: .type)
        if typeStr == "Update" {
            // For backwards compatibility with older versions of @concordium/wallet-connectors.
            type = TransferType.transferUpdate
        } else if typeStr == "transfer" {
            type = TransferType.simpleTransfer
        } else if let t = TransferType(rawValue: typeStr) {
            type = t
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid transaction type '\(typeStr)'")
        }
    }
}


enum SessionRequestDataType {
    case signMessage(SignMessagePayload)
    case simpleTransfer(SimpleTransferRequestParams)
    case signAndSend(ContractUpdateRequestParams)
    
    /// Basically we support two types of incoming wallet connect requests: `sign_message` & `sign_message`
    /// In case of `sign_message` wee need to determine what king of request is: send or update.
    /// having this info we can properly map income request data payload
    init(sessionRequest: Request) throws {
        switch sessionRequest.method {
            case "sign_message":
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: sessionRequest.params.value, options: [])
                    let payload: SignMessagePayload = try JSONDecoder().decode(SignMessagePayload.self, from: jsonData)
                    self = .signMessage(payload)
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            case "sign_and_send_transaction":
                do {
                    let contractType = try sessionRequest.params.get(SessionRequestType.self)
                    
                    switch contractType.type {
                        case .simpleTransfer:
                            let params = try sessionRequest.params.get(SimpleTransferRequestParams.self)
                            self = .simpleTransfer(params)
                        default:
                            let params = try sessionRequest.params.get(ContractUpdateRequestParams.self)
                            self = .signAndSend(params)
                    }
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            default:
                throw SessionRequstError.invalidRequestmethod
        }
    }
}
