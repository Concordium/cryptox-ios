//
//  UpdateRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import ReownWalletKit

final class TransferUpdateRequestModel: SessionRequestDataProvidable {
    @Published var title: String = "Sign Transaction"
    @Published var subtitle: String? = "Transfer Update"
    
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
        let txCost = try await getLocalContractUpdateCost(params: params)
        let transfer = getTransfer(for: params, energy: txCost.energy)
        let result = try await createAndPerform(params: params, account: account, transfer: transfer).singleOutput()
        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result]))
        )
    }
    
    
    @MainActor
    func checkBalance(account: AccountEntity, params: ContractUpdateRequestParams) async throws -> Bool {
        let txCost = try await getLocalContractUpdateCost(params: params)
        let amount = Int(params.payload.amount) ?? 0
        let transactionCost = Int(txCost.cost) ?? 0
        return account.forecastBalance > amount + transactionCost
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
    
    private func getLocalContractUpdateCost(params: ContractUpdateRequestParams) async throws -> TransferCost {
        guard let transactionsService = transactionsService as? TransactionsService else {
            throw SessionRequstError.generic("Unsupported transaction service")
        }

        let chainParameters = try await transactionsService.getChainParameters().async()
        let energy = try calculateContractUpdateEnergy(params: params)
        let cost = try calculateMicroCcdCost(energy: energy, chainParameters: chainParameters)
        return TransferCost(energy: energy, cost: cost.toString())
    }

    private func calculateContractUpdateEnergy(params: ContractUpdateRequestParams) throws -> Int {
        guard params.payload.maxContractExecutionEnergy >= 0 else {
            throw SessionRequstError.generic("Invalid max contract execution energy")
        }

        let signatureCount = 1
        // Account transaction header: account address (32), nonce (8), energy (8), payload size (4), expiry (8).
        let accountTransactionHeaderSize = 32 + 8 + 8 + 4 + 8
        // Update contract payload: amount (8), contract address (16), receive name size (2), parameter size (2).
        let payloadSize = 8 + 16 + 2 + byteCount(hex: params.payload.message) + 2 + params.payload.receiveName.utf8.count
        // Base energy formula: A * signatures + B * (header size + payload size) + contract execution energy.
        // Protocol constants A = 100 and B = 1.
        let signatureEnergy = try checkedMultiply(100, signatureCount)
        let verificationEnergy = try checkedAdd(signatureEnergy, accountTransactionHeaderSize)
        let transactionEnergy = try checkedAdd(verificationEnergy, payloadSize)
        return try checkedAdd(transactionEnergy, params.payload.maxContractExecutionEnergy)
    }

    private func calculateMicroCcdCost(energy: Int, chainParameters: ChainParametersResponse) throws -> Int {
        guard energy >= 0 else {
            throw SessionRequstError.generic("Invalid transaction energy")
        }
        guard chainParameters.euroPerEnergy.denominator > 0, chainParameters.microGTUPerEuro.denominator > 0 else {
            throw SessionRequstError.generic("Invalid chain parameter denominator")
        }

        let numerator = Decimal(energy)
            * Decimal(chainParameters.euroPerEnergy.numerator)
            * Decimal(chainParameters.microGTUPerEuro.numerator)
        let denominator = Decimal(chainParameters.euroPerEnergy.denominator)
            * Decimal(chainParameters.microGTUPerEuro.denominator)
        let decimalCost = NSDecimalNumber(decimal: numerator / denominator)
        let roundedCost = decimalCost.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .up,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
        guard roundedCost.doubleValue.isFinite,
              roundedCost.compare(NSDecimalNumber(value: Int.max)) != .orderedDescending else {
            throw SessionRequstError.generic("Transaction cost exceeds supported range")
        }
        return roundedCost.intValue
    }

    private func checkedAdd(_ lhs: Int, _ rhs: Int) throws -> Int {
        let result = lhs.addingReportingOverflow(rhs)
        guard !result.overflow else {
            throw SessionRequstError.generic("Transaction energy exceeds supported range")
        }
        return result.partialValue
    }

    private func checkedMultiply(_ lhs: Int, _ rhs: Int) throws -> Int {
        let result = lhs.multipliedReportingOverflow(by: rhs)
        guard !result.overflow else {
            throw SessionRequstError.generic("Transaction energy exceeds supported range")
        }
        return result.partialValue
    }

    private func byteCount(hex: String) -> Int {
        let hexString = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        return (hexString.utf8.count + 1) / 2
    }
    
    private func getTransfer(for params: ContractUpdateRequestParams, energy: Int) -> any TransferDataType {
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = params.type
        transfer.amount = params.payload.amount
        transfer.fromAddress = params.sender
        transfer.from = params.sender
        transfer.toAddress = params.sender
        transfer.expiry = Date().addingTimeInterval(10 * 60)
        transfer.energy = energy
        transfer.receiveName = params.payload.receiveName
        transfer.params = params.payload.message
        transfer.contractAddressObject = ContractAddressObject()
        transfer.contractAddressObject.index = params.payload.address.index?.toString() ?? ""
        transfer.contractAddressObject.subindex = params.payload.address.subindex?.toString() ?? ""
        return transfer
    }
}
