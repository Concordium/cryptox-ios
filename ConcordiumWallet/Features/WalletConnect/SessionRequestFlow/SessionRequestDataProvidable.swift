//
//  SessionRequestDataProvidable.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import ReownWalletKit


protocol SessionRequestDataProvidable {
    var title: String { get }
    var subtitle: String? { get }
    
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
        storageManager: StorageManagerProtocol,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService
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
            case .tokenUpdate(let params):
                return TokenUpdateRequestModel(
                    params: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    storageManager: storageManager,
                    concordiumClient: concordiumClient
                )
            case .verifiablePresentation(let params):
                return VerifiablePresentationRequestModel(
                    payload: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    concordiumClient: concordiumClient,
                    identitiesService: identitiesService
                )
            case .verifiablePresentationV1(let requestV1):
                return VerifiablePresentationV1RequestModel(
                    requestV1: requestV1,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    storageManager: storageManager,
                    concordiumClient: concordiumClient,
                    identitiesService: identitiesService
                )
            case .sponsoredTransaction(let params):
                // Get networkManager from transactionsService (it's a concrete class with networkManager property)
                guard let transactionsServiceConcrete = transactionsService as? TransactionsService else {
                    return nil
                }
                return SponsoredTransactionRequestModel(
                    params: params,
                    account: account,
                    sessionRequest: sessionRequest,
                    transactionsService: transactionsService,
                    mobileWallet: mobileWallet,
                    passwordDelegate: passwordDelegate,
                    storageManager: storageManager,
                    concordiumClient: concordiumClient,
                    networkManager: transactionsServiceConcrete.networkManager
                )
        }
    }
}
