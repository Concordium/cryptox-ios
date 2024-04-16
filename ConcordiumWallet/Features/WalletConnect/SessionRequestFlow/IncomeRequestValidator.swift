//
//  IncomeRequestValidator.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Web3Wallet
import WalletConnectVerify


enum SessionRequstError: Error {
    case environmentMismatch(chain: String), accountNotFound, accountMissmatch, noValidWCSession(topic: String)
    case invalidRequestmethod, invalidRequestPayload, unSupportedRequestMethod
    
    var errorMessage: String {
        switch self {
            case .environmentMismatch(let chain):
                "The session proposal did not contain a valid namespace. Allowed namespaces are: \(chain)"
            case .accountNotFound, .accountMissmatch:
                "Can't find apropriate acount to sign"
            case .noValidWCSession(let topic):
                "No session found for the received topic: \(topic)"
            case .invalidRequestmethod: "Unknown sesion requestmethod"
            case .invalidRequestPayload: "Invalid request payload"
            case .unSupportedRequestMethod: "Unsupported request method"
        }
    }
}

final class IncomeRequestValidator {
    static var currentChain: String {
#if MAINNET
        "ccd:mainnet"
#else
        "ccd:testnet"
#endif
    }
    
    typealias Validationresult = (requestType: SessionRequestDataType, account: AccountEntity)
    
    @MainActor
    static func validate(_ sessionRequest: Request, storageManager: StorageManagerProtocol) throws -> Validationresult {
        // Find the session that the request matches. The session will allow us to extract
        // the account that the request is for.
        // A WalletConnect session should always be for exactly one account. If there are more, then
        // we cannot uniquely determine the correct account address.
        guard
            let session = Web3Wallet.instance.getSessions().first(where: { $0.topic == sessionRequest.topic }),
            session.accounts.count == 1,
            let walletConnectAccount = session.accounts.first
        else {
            throw SessionRequstError.noValidWCSession(topic: sessionRequest.topic)
        }
        
        // Ensure that app chain and requested chain is same
        guard sessionRequest.chainId.absoluteString == currentChain else {
            throw SessionRequstError.environmentMismatch(chain: sessionRequest.chainId.absoluteString)
        }
    
        // Get `Account` associated with Wallet Connect request
        guard let account = storageManager.getAccounts().first(where: { $0.address == walletConnectAccount.address }) as? AccountEntity else {
            throw SessionRequstError.accountNotFound
        }
        
        return (try SessionRequestDataType.init(sessionRequest: sessionRequest), account)
    }
}
