//
//  CIS2TokenTransferModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 15.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import BigInt
import UIKit

enum TokenTransferNotifyDestination {
    case none
    case legacyQrConnect
}

enum TransferTokenError: Error {
    case insuficientData
}

final class CIS2TokenTransferModel {
    @Published var tokenType: CXTokenType
    @Published var recipient: String?
    @Published var transaferCost: TransferCost?
    @Published var amountTokenSend: BigDecimal = .zero
    @Published var maxAmountTokenSend: BigDecimal = .zero
    @Published var tokenGeneralBalance: BigDecimal = .zero
    @Published var ccdTokenDisposalBalance: BigDecimal = .zero
    
    let account: AccountDataType
    let notifyDestination: TokenTransferNotifyDestination
    
    private var cancellables = [AnyCancellable]()
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let passwordDelegate: RequestPasswordDelegate
    private var onTxSuccess: (String) -> Void
    private var onTxReject: () -> Void
    
    ///
    /// `notifyDestination` - describes whch service you need to send ``
    init(
        tokenType: CXTokenType,
        account: AccountDataType,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider,
        notifyDestination: TokenTransferNotifyDestination,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate(),
        onTxSuccess: @escaping (String) -> Void,
        onTxReject: @escaping () -> Void
    ) {
        self.tokenType = tokenType
        self.account = account
        self.dependencyProvider = dependencyProvider
        self.notifyDestination = notifyDestination
        self.passwordDelegate = passwordDelegate
        self.onTxSuccess = onTxSuccess
        self.onTxReject = onTxReject
        
        subscribe()
        
        Task {
            await updateMaxAmount()
        }
    }
    
    public func sendTxRejectQRConnectMessage() {
        onTxReject()
    }
    
    public func getTokenMaxAmount() async throws -> BigDecimal {
        switch tokenType {
            case .ccd:
                return .init(BigInt(account.forecastAtDisposalBalance) - BigInt(stringLiteral: transaferCost?.cost ?? "0"), 6)
            case .cis2(let cis2Token):
                return try await CIS2TokenService.getCIS2TokenBalance(index: cis2Token.contractAddress.index, tokenIds: [cis2Token.tokenId], address: self.account.address)
                    .first
                    .map { balance -> BigDecimal in
                        return .init(BigInt(stringLiteral: balance.balance), cis2Token.metadata.decimals ?? 0)
                    } ?? .zero(cis2Token.metadata.decimals ?? 0)
        }
    }
    
    public func getTxCost() async throws -> TransferCost {
        switch tokenType {
            case .cis2(let cIS2Token):
                guard let address = recipient, address.isEmpty == false, !amountTokenSend.value.isZero else { return .zero }
                return try await self.getCIS2TxCost(cIS2Token, amount: amountTokenSend)
            case .ccd:
                return try await getCCDTxCost()
        }
    }
    
    private func subscribe() {
        Publishers.CombineLatest3($recipient, $tokenType, $amountTokenSend).sink(receiveValue: { [weak self] (address, tokenType, amount) in
            await self?.updateMaxAmount()

            guard let self = self else { return }
            switch tokenType {
                case .cis2(let cIS2Token):
                    guard let address = address, address.isEmpty == false, !amount.value.isZero else { return }
                    await self.updateCIS2TransferConst(cIS2Token, amount: amount)
                case .ccd:
                    await updateCCDTransferCost()
            }
            await self.updateMaxAmount()
        }).store(in: &cancellables)
    }

    public func getCCDTxCost() async throws -> TransferCost {
        return try await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .simpleTransfer, costParameters: [])
            .async()
    }
    
    public func getCIS2TxCost(_ token: CIS2Token, amount: BigDecimal) async throws -> TransferCost {
        guard let to = recipient else { return .zero }
        return try await self.updateTxCost(token: token, to: to, amount: amount, recipient: to)
    }
    
    @MainActor
    public func updateMaxAmount() async {
        switch self.tokenType {
            case .ccd:
                await updateCCDTransferCost()
                self.maxAmountTokenSend = .init(BigInt(account.forecastAtDisposalBalance) - BigInt(stringLiteral: transaferCost?.cost ?? "0"), 6)
                self.tokenGeneralBalance = .init(BigInt(account.forecastBalance), 6)
                self.ccdTokenDisposalBalance = .init(BigInt(account.forecastAtDisposalBalance), 6)
            case .cis2(let token):
                guard let balance = try? await CIS2TokenService.getCIS2TokenBalance(index: token.contractAddress.index, tokenIds: [token.tokenId], address: self.account.address).first else {
                    self.maxAmountTokenSend = .zero
                    self.tokenGeneralBalance = .zero
                    self.tokenGeneralBalance = .zero
                    return
                }
                if token.metadata.unique == true {
                    self.maxAmountTokenSend = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
                    self.tokenGeneralBalance = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
                } else {
                    self.maxAmountTokenSend = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
                    self.tokenGeneralBalance = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
                }
        }
    }
    
    func executeTransaction() async throws -> AnyPublisher<TransferEntity, Error> {
        return try await callTransaction().tryMap { [weak self] entity in
            guard let self = self else { return entity }
            switch self.notifyDestination {
                case .legacyQrConnect:
//                    self.legacyQRConnectService?.sendPaymentMessage(hash: entity.submissionId ?? "")
                    self.onTxSuccess(entity.submissionId ?? "")
                case .none: break
            }
            return entity
        }.eraseToAnyPublisher()
    }
}

extension CIS2TokenTransferModel {
    @MainActor
    private func updateCIS2TransferConst(_ token: CIS2Token, amount: BigDecimal) async {
        guard let to = recipient else { return }
        self.transaferCost = try? await self.updateTxCost(token: token, to: to, amount: amount, recipient: to)
    }
    
    @MainActor
    private func updateTxCost(token: CIS2Token, to: String, amount: BigDecimal, recipient: String) async throws -> TransferCost {
        let serializedTransferParams = try MobileWalletFacade().serializeTokenTransferParameters(input: TokenTransferParameters(tokenId: token.tokenId, amount: String(amount.value), from: account.address, to: recipient))
        return try await dependencyProvider
            .transactionsService()
            .getTransferCost(
                transferType: .update,
                costParameters: [
                    .amount("0"),
                    .sender(account.address),
                    .contractIndex(token.contractAddress.index),
                    .contractSubindex(token.contractAddress.subindex),
                    .receiveName("\(token.contractName).transfer"),
                    .parameter(serializedTransferParams),
                ]
            )
            .eraseToAnyPublisher()
            .async()
    }
    
    @MainActor
    private func updateCCDTransferCost() async {
        self.transaferCost = try? await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .simpleTransfer, costParameters: [])
            .async()
    }
}

extension CIS2TokenTransferModel {
    private func callTransaction() async throws -> AnyPublisher<TransferEntity, Error> {
        switch self.tokenType {
            case .cis2(let cIS2Token):
                guard let recipient = self.recipient,
                      let transaferCost = self.transaferCost
                else { return .fail(TransferTokenError.insuficientData) }
                return try await transferCis2Token(cIS2Token, amount: self.amountTokenSend, to: recipient, txCost: transaferCost)
            case .ccd:
                return try await simpleTransferCCDToken()
        }
    }
    
    @MainActor
    private func simpleTransferCCDToken() async throws -> AnyPublisher<TransferEntity, Error> {
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = .simpleTransfer
        transfer.amount = String(self.amountTokenSend.value)
        transfer.fromAddress = self.account.address
        transfer.toAddress = self.recipient ?? ""
        transfer.cost = self.transaferCost?.cost ?? "100000"
        transfer.energy = self.transaferCost?.energy ?? 0

        return dependencyProvider.transactionsService()
            .performTransfer(transfer, from: self.account, requestPasswordDelegate: self.passwordDelegate)
            .tryMap { transferDataType -> TransferEntity in
                _ = try self.dependencyProvider.storageManager().storeTransfer(transferDataType)
                return transferDataType as! TransferEntity
            }
            .eraseToAnyPublisher()
    }
    
    @MainActor
    private func transferCis2Token(_ token: CIS2Token, amount: BigDecimal, to: String, txCost: TransferCost) async throws -> AnyPublisher<TransferEntity, Error> {
        let serializedTransferParams = try MobileWalletFacade().serializeTokenTransferParameters(input: TokenTransferParameters(tokenId: token.tokenId, amount: String(self.amountTokenSend.value), from: self.account.address, to: to))
        
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = .transferUpdate
        transfer.from = self.account.address
        transfer.toAddress = to
        transfer.expiry = Date().addingTimeInterval(10 * 60)
        transfer.energy = txCost.energy
        
        transfer.receiveName = token.contractName + ".transfer"
        transfer.params = serializedTransferParams

        return dependencyProvider.transactionsService()
            .performTransferUpdate(transfer, from: self.account, contractAddress: .init(index: token.contractAddress.index, subindex: token.contractAddress.subindex), requestPasswordDelegate: self.passwordDelegate)
            .tryMap { transferDataType -> TransferEntity in
                _ = try self.dependencyProvider.storageManager().storeTransfer(transferDataType)
                return transferDataType as! TransferEntity
            }
            .eraseToAnyPublisher()
    }
}
