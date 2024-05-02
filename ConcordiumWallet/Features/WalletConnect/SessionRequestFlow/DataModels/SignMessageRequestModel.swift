//
//  SignMessageRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify
import Combine

final class SignMessageRequestModel: SessionRequestDataProvidable {
    @Published var title: String = "Sign Message"
    
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let payload: SignMessagePayload
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    
    init(
        payload: SignMessagePayload,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate
    ) {
        self.sessionRequest = sessionRequest
        self.payload = payload
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        return true
    }
    
    @MainActor
    func approveRequest() async throws {
        let result = try await mobileWallet
            .signMessage(for: account, message: payload.message, requestPasswordDelegate: passwordDelegate)
            .async()
        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(result))
        )
    }
}
