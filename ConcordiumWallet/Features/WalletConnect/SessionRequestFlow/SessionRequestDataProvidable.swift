//
//  SessionRequestDataProvidable.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify

protocol SessionRequestDataProvidable {
    var title: String { get }
    
    func checkAllSatisfy() async throws -> Bool
    func approveRequest() async throws
}

final class SessionRequestDataModelProvider {
    static func model(
        for type: SessionRequestDataType,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        storageManager: StorageManagerProtocol
    ) -> SessionRequestDataProvidable? {
        switch type {
            case .signMessage(let signMessagePayload):
                return SignMessageRequestModel(
                    payload: signMessagePayload,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate
                )
            case .simpleTransfer(let params):
                return SimpleTrasferRequestModel(
                    params: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    storageManager: storageManager
                )
            case .signAndSend(let params):
                return TransferUpdateRequestModel(
                    params: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    storageManager: storageManager
                )
            case .verifiablePresentation(let params):
                return VerifiablePresentationRequestModel(
                    payload: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate
                )
        }
    }
}
