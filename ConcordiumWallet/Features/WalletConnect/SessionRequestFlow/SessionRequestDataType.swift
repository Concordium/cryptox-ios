//
//  SessionRequestDataType.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Concordium
import Foundation
import ReownWalletKit

enum SessionRequestDataType {
    case signMessage(SignMessagePayload)
    case simpleTransfer(SimpleTransferRequestParams)
    case signAndSend(ContractUpdateRequestParams)
    case tokenUpdate(TokenUpdateRequestParams)
    case verifiablePresentation(WalletConnectRequestVerifiablePresentationParam)
    
    init(sessionRequest: Request) throws {
        switch sessionRequest.method {
            case "request_verifiable_presentation":
                do {
                    struct ParamsData: Codable {
                        let paramsJson: String
                    }
                    let paramsData = try sessionRequest.params.get(ParamsData.self)
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let value = try JSONDecoder().decode(WalletConnectRequestVerifiablePresentationParam.self, from: paramsData.paramsJson.data(using: .utf8)!)
                    
                    self = .verifiablePresentation(value)
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
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
                    case .tokenUpdate:
                        let params = try sessionRequest.params.get(TokenUpdateRequestParams.self)
                        self = .tokenUpdate(params)
                    default:
                        let params = try sessionRequest.params.get(ContractUpdateRequestParams.self)
                        self = .signAndSend(params)
                    }
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            default:
                throw SessionRequstError.invalidRequestMethod
        }
    }
}
