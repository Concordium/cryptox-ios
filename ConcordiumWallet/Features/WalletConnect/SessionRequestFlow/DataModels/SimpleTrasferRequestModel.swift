//
//  SimpleTrasferRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify
import Combine
import BigInt

final class SimpleTrasferRequestModel: SessionRequestDataProvidable {
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let params: SimpleTransferRequestParams
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let storageManager: StorageManagerProtocol
        
    init(
        params: SimpleTransferRequestParams,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        storageManager: StorageManagerProtocol
    ) {
        self.sessionRequest = sessionRequest
        self.params = params
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        self.storageManager = storageManager
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        try await checkBalance(account: account, params: params)
    }
    
    @MainActor
    func approveRequest() async throws {
        let txCost = try await transactionsService
            .getTransferCost(transferType: .simpleTransfer, costParameters: params.costParameters())
            .async()
        let params = try sessionRequest.params.get(SimpleTransferRequestParams.self)
        let transfer = getTransfer(for: params, txCost: txCost)
        let result = try await createAndPerform(params: params, account: account, transfer: transfer).singleOutput()
        try await Web3Wallet.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result]))
        )
    }
    
    @MainActor
    func checkBalance(account: AccountEntity, params: SimpleTransferRequestParams) async throws -> Bool {
        let txCost = try await transactionsService
            .getTransferCost(transferType: .simpleTransfer, costParameters: params.costParameters())
            .async()
        return BigDecimal.init(BigInt(account.forecastAtDisposalBalance) - BigInt(stringLiteral: txCost.cost), 6).value > BigDecimal(BigInt(stringLiteral: params.payload.amount), 6).value
    }
    
    @MainActor
    private func createAndPerform(params: SimpleTransferRequestParams, account: AccountEntity, transfer: any TransferDataType) async throws -> AnyPublisher<String?, Error> {
        transactionsService
            .performTransfer(transfer, from: account, requestPasswordDelegate: passwordDelegate)
                    .tryMap { transferDataType -> String? in
                _ = try self.storageManager.storeTransfer(transferDataType)
                return transferDataType.submissionId
            }
            .eraseToAnyPublisher()
    }
    
    private func getTransfer(for params: SimpleTransferRequestParams, txCost: TransferCost) -> any TransferDataType {
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = .simpleTransfer
        transfer.amount = String(params.payload.amount)
        transfer.fromAddress = params.sender
        transfer.toAddress = params.payload.toAddress
        transfer.cost = txCost.cost
        transfer.energy = txCost.energy
        return transfer
    }
}
