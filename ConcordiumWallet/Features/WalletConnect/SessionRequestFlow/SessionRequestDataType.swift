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
import ConcordiumWalletCrypto

enum SessionRequestDataType {
    case signMessage(SignMessagePayload)
    case simpleTransfer(SimpleTransferRequestParams)
    case signAndSend(ContractUpdateRequestParams)
    case tokenUpdate(TokenUpdateRequestParams)
    case verifiablePresentation(WalletConnectRequestVerifiablePresentationParam)
    case verifiablePresentationV1(RequestV1)
    case sponsoredTransaction(SponsoredTransactionRequestParams)
    
    init(sessionRequest: Request) throws {
        // Validate that the method is supported before processing
        guard let method = WalletConnectConstants(method: sessionRequest.method) else {
            throw SessionRequstError.invalidRequestMethod
        }
        
        switch method {
            case .requestVerifiablePresentation:
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
            case .requestVerifiablePresentationV1:
                do {
                    // For v1, params might be a JSON string (like v0) or direct object
                    var jsonData: Data
                    
                    // Try to get paramsJson string first (like v0 format)
                    if let paramsDict = sessionRequest.params.value as? [String: Any],
                       let paramsJsonString = paramsDict["paramsJson"] as? String {
                        guard let data = paramsJsonString.data(using: .utf8) else {
                            throw SessionRequstError.unSupportedRequestMethod
                        }
                        jsonData = data
                    } else if let paramsString = sessionRequest.params.value as? String {
                        // Params might be a direct JSON string
                        guard let data = paramsString.data(using: .utf8) else {
                            throw SessionRequstError.unSupportedRequestMethod
                        }
                        jsonData = data
                    } else {
                        // Try direct object serialization
                        jsonData = try JSONSerialization.data(withJSONObject: sessionRequest.params.value, options: [])
                    }
                    
                    let (requestV1, transactionRef) = try RequestV1Decoder.decode(from: jsonData)
                    // Store transactionRef in the requestV1 context if needed
                    // For now, we'll pass it through - the model will extract it from the original JSON
                    self = .verifiablePresentationV1(requestV1)
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            case .signMessage:
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: sessionRequest.params.value, options: [])
                    let payload: SignMessagePayload = try JSONDecoder().decode(SignMessagePayload.self, from: jsonData)
                    self = .signMessage(payload)
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            case .signAndSendTransaction:
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
            case .signAndSendSponsoredTransaction:
                do {
                    let params = try sessionRequest.params.get(SponsoredTransactionRequestParams.self)
                    self = .sponsoredTransaction(params)
                } catch {
                    throw SessionRequstError.unSupportedRequestMethod
                }
            default:
                throw SessionRequstError.invalidRequestMethod
        }
    }
}
