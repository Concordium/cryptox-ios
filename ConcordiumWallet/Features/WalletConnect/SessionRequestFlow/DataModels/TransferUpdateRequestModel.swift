//
//  UpdateRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import ReownWalletKit
import WalletConnectVerify
import Combine

final class TransferUpdateRequestModel: SessionRequestDataProvidable {
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let params: ContractUpdateRequestParams
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let storageManager: StorageManagerProtocol
    
    init(
        params: ContractUpdateRequestParams,
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
        let params = try sessionRequest.params.get(ContractUpdateRequestParams.self)
        let transfer = getTransfer(for: params)
        let result = try await createAndPerform(params: params, account: account, transfer: transfer).singleOutput()
        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result]))
        )
    }
    
    
    @MainActor
    func checkBalance(account: AccountEntity, params: ContractUpdateRequestParams) async throws -> Bool {
        let transfer = self.getTransfer(for: params)
        let txCost = try await transactionsService.getTransferCost(
            transferType: transfer.transferType.toWalletProxyTransferType(),
            costParameters: params.costParameters()
        ).async()
        let nrgCCDAmount = self.getNrgCCDAmount(
            nrgLimit: params.payload.maxContractExecutionEnergy,
            cost: txCost.cost.floatValue,
            energy: txCost.energy.string.floatValue
        )
        
        let amount = Int(params.payload.amount) ?? 0
        let ccdAmount =  GTU(intValue: amount)
        let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdTotalBalance = GTU(intValue: account.forecastBalance)
        
        return ccdTotalBalance.intValue > ccdTotalAmount.intValue
    }
    
    @MainActor
    private func createAndPerform(params: ContractUpdateRequestParams, account: AccountEntity, transfer: any TransferDataType) async throws -> AnyPublisher<String?, Error> {
        transactionsService
            .performTransferUpdate(transfer, from: account, contractAddress: params.payload.address, requestPasswordDelegate: passwordDelegate)
            .tryMap { transferDataType -> String? in
                _ = try self.storageManager.storeTransfer(transferDataType)
                return transferDataType.submissionId
            }
            .eraseToAnyPublisher()
    }
    
    private func getNrgCCDAmount(nrgLimit: Int, cost: Float, energy: Float) -> Int {
        let _nrgLimit = Float(nrgLimit)
        let nrgCCDAmount = Float(_nrgLimit * (cost / energy) / 1000000.0)
        return Int(ceil(nrgCCDAmount))
    }
    
    private func getTransfer(for params: ContractUpdateRequestParams) -> any TransferDataType {
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = params.type
        transfer.amount = params.payload.amount
        transfer.fromAddress = params.sender
        transfer.from = params.sender
        transfer.toAddress = params.sender
        transfer.expiry = Date().addingTimeInterval(10 * 60)
        transfer.energy = params.payload.maxContractExecutionEnergy
        transfer.receiveName = params.payload.receiveName
        transfer.params = params.payload.message
        transfer.contractAddressObject = ContractAddressObject()
        transfer.contractAddressObject.index = params.payload.address.index?.toString() ?? ""
        transfer.contractAddressObject.subindex = params.payload.address.subindex?.toString() ?? ""
        return transfer
    }
}
