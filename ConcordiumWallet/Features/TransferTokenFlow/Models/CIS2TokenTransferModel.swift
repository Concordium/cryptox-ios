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
import Concordium

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
    @Published var memo: Memo?
    
    let account: AccountDataType
    let notifyDestination: TokenTransferNotifyDestination
    
    private var cancellables = [AnyCancellable]()
    private let dependencyProvider: ServicesProvider
    private let passwordDelegate: RequestPasswordDelegate
    private var onTxSuccess: (String) -> Void
    private var onTxReject: () -> Void
    
    let cis2Service: CIS2Service
    
    ///
    /// `notifyDestination` - describes whch service you need to send ``
    init(
        tokenType: CXTokenType,
        account: AccountDataType,
        dependencyProvider: ServicesProvider,
        notifyDestination: TokenTransferNotifyDestination,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate(),
        memo: Memo?,
        onTxSuccess: @escaping (String) -> Void,
        onTxReject: @escaping () -> Void
    ) {
        self.tokenType = tokenType
        self.account = account
        self.dependencyProvider = dependencyProvider
        self.notifyDestination = notifyDestination
        self.passwordDelegate = passwordDelegate
        self.memo = memo
        self.onTxSuccess = onTxSuccess
        self.onTxReject = onTxReject
        
        self.cis2Service = CIS2Service(networkManager: dependencyProvider.networkManager(), storageManager: dependencyProvider.storageManager())
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
            return try await cis2Service.fetchTokensBalance(contractIndex: String(cis2Token.contractAddress.index), accountAddress: self.account.address, tokenId: cis2Token.tokenId)
                .first
                .map { balance -> BigDecimal in
                    return .init(BigInt(stringLiteral: balance.balance), cis2Token.metadata.decimals ?? 0)
                } ?? .zero(cis2Token.metadata.decimals ?? 0)
        case .plt(let token):
            return .init(BigInt(stringLiteral: token.token.tokenState.totalSupply.value), token.token.tokenState.totalSupply.decimals)
        }
    }
    
    public func getTxCost() async throws -> TransferCost {
        switch tokenType {
        case .cis2(let cIS2Token):
            guard let address = recipient, address.isEmpty == false, !amountTokenSend.value.isZero else { return .zero }
            return try await self.getCIS2TxCost(cIS2Token, amount: amountTokenSend)
        case .ccd:
            return try await getCCDTxCost()
        case .plt(let token):
            return try await getCCDTxCost()
        }
    }
    
    private func subscribe() {
        Publishers.CombineLatest4($recipient, $tokenType, $amountTokenSend, $memo).sink(receiveValue: { [weak self] (address, tokenType, amount, memo) in
            await self?.updateMaxAmount()
            
            guard let self = self else { return }
            switch tokenType {
            case .cis2(let cIS2Token):
                guard let address = address, address.isEmpty == false, !amount.value.isZero else { return }
                await self.updateCIS2TransferConst(cIS2Token, amount: amount)
            case .ccd:
                await updateCCDTransferCost()
            case .plt(let token):
                await updateCCDTransferCost()
            }
            await self.updateMaxAmount()
        }).store(in: &cancellables)
    }
    
    public func getCCDTxCost() async throws -> TransferCost {
        return try await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .simpleTransfer, costParameters: TransferCostParameter.parametersForMemoSize(memo?.size))
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
            self.tokenGeneralBalance = .init(BigInt(account.forecastAtDisposalBalance), 6)
            self.ccdTokenDisposalBalance = .init(BigInt(account.forecastAtDisposalBalance), 6)
        case .cis2(let token):
            guard let balance = try? await cis2Service.fetchTokensBalance(contractIndex: String(token.contractAddress.index), accountAddress: self.account.address, tokenId: token.tokenId).first else {
                self.maxAmountTokenSend = .zero
                self.tokenGeneralBalance = .zero
                self.tokenGeneralBalance = .zero
                return
            }
            self.maxAmountTokenSend = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
            self.tokenGeneralBalance = .init(BigInt(stringLiteral: balance.balance), token.metadata.decimals ?? 0)
        case .plt(let token):
            await updateCCDTransferCost()
            
            self.maxAmountTokenSend = .init(BigInt(stringLiteral: token.tokenAccountState.balance.value), token.tokenAccountState.balance.decimals)
            self.tokenGeneralBalance = .init(BigInt(stringLiteral: token.tokenAccountState.balance.value), token.tokenAccountState.balance.decimals)
        }
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
                    .memoSize(memo?.size ?? 0)
                ]
            )
            .eraseToAnyPublisher()
            .async()
    }
    
    @MainActor
    private func updateCCDTransferCost() async {
        self.transaferCost = try? await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .simpleTransfer, costParameters: TransferCostParameter.parametersForMemoSize(memo?.size))
            .async()
    }
}

extension CIS2TokenTransferModel {
    func executeTransfer() async throws {
        guard let recipient = self.recipient else { throw TransferTokenError.insuficientData }
        
        switch self.tokenType {
        case .cis2(let cIS2Token):
            _ = try await ececuteTransferCIS2(token: cIS2Token, recipient: recipient)
        case .ccd:
            _  = try await executeTransferCCD(recipient: recipient)
        case .plt(let token):
            _ = try await executeTransferPLT(token, recipient: recipient)
        }
    }
    
    @MainActor
    func executeTransferPLT(_ token: AccountPLTToken, recipient: String) async throws -> TransactionStatus {
        let pwHash = try await self.passwordDelegate.requestUserPassword(keychain: dependencyProvider.keychainWrapper())
        guard
            let encryptedAccountDataKey = account.encryptedAccountData,
            let accountKeys = try? dependencyProvider.storageManager().getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get()
        else { throw WalletError.invalidInput }
        
        var concordiumMemo: Concordium.Memo? = nil
        
        if let memoData = memo?.data {
            concordiumMemo = Concordium.Memo(memoData)
        }
        
        let submittedTransaction = try await dependencyProvider.concordiumClient().transferPLT(
            token: token,
            sender: AccountAddress(base58Check: self.account.address),
            amount: self.amountTokenSend,
            receiver: AccountAddress(base58Check: recipient),
            keys: accountKeys,
            memo: concordiumMemo
        )
        
        return try await dependencyProvider.concordiumClient().getTransactionStatus(submittedTransaction.hash)
    }
    
    @MainActor
    func executeTransferCCD(recipient: String) async throws -> TransactionStatus {
        let pwHash = try await self.passwordDelegate.requestUserPassword(keychain: dependencyProvider.keychainWrapper())
        guard
            let encryptedAccountDataKey = account.encryptedAccountData,
            let accountKeys = try? dependencyProvider.storageManager().getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get()
        else { throw WalletError.invalidInput }
        
        var concordiumMemo: Concordium.Memo? = nil
        
        if let memoData = memo?.data {
            concordiumMemo = Concordium.Memo(memoData)
        }
        
        let submittedTransaction = try await dependencyProvider.concordiumClient().transferCCD(
            sender: AccountAddress(base58Check: self.account.address),
            amount: CCD.init(microCCD: MicroCCDAmount(Double(self.amountTokenSend.value))),
            receiver: AccountAddress(base58Check: recipient),
            keys: accountKeys,
            memo: concordiumMemo
        )
        
        return try await dependencyProvider.concordiumClient().getTransactionStatus(submittedTransaction.hash)
    }
    
    @MainActor
    func ececuteTransferCIS2(token: CIS2Token, recipient: String) async throws -> TransactionStatus {
        let pwHash = try await self.passwordDelegate.requestUserPassword(keychain: dependencyProvider.keychainWrapper())
        guard
            let encryptedAccountDataKey = account.encryptedAccountData,
            let accountKeys = try? dependencyProvider.storageManager().getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get()
        else { throw WalletError.invalidInput }
        
        let submittedTransaction = try await dependencyProvider.concordiumClient().transferCIS2(
            sender: AccountAddress(base58Check: self.account.address),
            receiver: AccountAddress(base58Check: recipient),
            keys: accountKeys,
            contractAddress: Concordium.ContractAddress(index: UInt64(token.contractAddress.index), subindex: UInt64(token.contractAddress.subindex)),
            tokenId: token.tokenId,
            amount: self.amountTokenSend.value
        )
        return try await dependencyProvider.concordiumClient().getTransactionStatus(submittedTransaction.hash)
    }
}
