//
//  ConcordiumClient.swift
//  CryptoX
//
//  Created by Max on 03.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

final class ConcordiumClient: ObservableObject {
    private let nodeClient: GRPCNodeClient
    var networkManager: NetworkManagerProtocol
    private let storageManager: StorageManagerProtocol
    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) throws {
        self.nodeClient = try GRPCNodeClient(url: URL(string: "https://grpc.testnet.concordium.com:20000")!)
        self.networkManager = networkManager
        self.storageManager = storageManager
        Task {
            do {
                let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(.init(base58Check: "3TCkXUUQ4vp4Ad8f96iSaN5NpKYgN3efev6STq2YW5oRBjnsZu")))
                print("ska -- \(accountInfo)")
            } catch {
                print("ska error -- \(error)")
            }
        }
    }
    
    func fetchKeys() -> AccountKeys {
        try! AccountKeys("")
    }
    
    func getAccountInfo(address: String) async throws -> AccountInfo {
        try await nodeClient.info(account: AccountIdentifier.address(.init(base58Check: address)))
    }
}

extension ConcordiumClient {
    func transferCCD(sender: AccountAddress, amount: CCD, receiver: AccountAddress, keys: AccountKeys, memo: Concordium.Memo?) async throws -> SubmittedTransaction {
        let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(sender))
        let transaction: AccountTransaction = AccountTransaction.transfer(sender: sender, receiver: receiver, amount: amount, memo: memo)
        let expiry: TransactionTime = Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
        let sequenceNumber: SequenceNumber = accountInfo.sequenceNumber
        
        let preparedAccountTransaction: PreparedAccountTransaction = transaction.prepare(sequenceNumber: sequenceNumber, expiry: expiry, signatureCount: Int(accountInfo.threshold))
    
        return try await send(preparedAccountTransaction, keys: keys)
    }
    
    func transferToPublic(account: AccountDataType, amount: CCD, receiver: AccountAddress, keys: AccountKeys, pwHash: String) async throws -> SubmittedTransaction {
        let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(.init(base58Check: account.address)))

        let inputEncryptedAmount: InputEncryptedAmount = self.getInputEncryptedAmount(for: account)
        
        let global: GlobalWrapper = try await networkManager.load(ResourceRequest(url: ApiConstants.global))
                
        let senderSecretKey = try getSecretEncryptionKey(for: account, pwHash: pwHash).get()
        
        let transaction: AccountTransaction = AccountTransaction.transferToPublic(
            sender: try .init(base58Check: account.address),
            global: .init(
                onChainCommitmentKey: Data(global.value.genesisString?.utf8 ?? "".utf8),
                bulletproofGenerators: Data(global.value.bulletproofGenerators?.utf8 ?? "".utf8),
                genesisString: global.value.genesisString ?? ""
            ),
            senderSecretKey: Data(senderSecretKey.utf8),
            inputAmount: Concordium.InputEncryptedAmount(
                aggEncryptedAmount: Data(inputEncryptedAmount.aggEncryptedAmount?.utf8 ?? "".utf8),
                aggAmount: UInt64(inputEncryptedAmount.aggAmount ?? "0") ?? 0,
                aggIndex: UInt64(inputEncryptedAmount.aggIndex ?? 0)
            ),
            toTransfer: amount
        )!
        let expiry: TransactionTime = Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
        let sequenceNumber: SequenceNumber = accountInfo.sequenceNumber
        
        let preparedAccountTransaction: PreparedAccountTransaction = transaction.prepare(sequenceNumber: sequenceNumber, expiry: expiry, signatureCount: Int(accountInfo.threshold))
    
        return try await send(preparedAccountTransaction, keys: keys)
    }
    
    private func getSecretEncryptionKey(for account: AccountDataType, pwHash: String) -> Result<String, Error> {
        guard let key = account.encryptedPrivateKey else { return .failure(MobileWalletError.invalidArgument) }
        return storageManager.getPrivateEncryptionKey(key: key, pwHash: pwHash)
            .mapError { $0 as Error }
    }
    
    
    /// Internal
    func send(sender: AccountAddress, amount: CCD, receiver: AccountAddress, keys: AccountKeys, memo: Concordium.Memo?) async throws -> SubmittedTransaction {
        let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(sender))
        
//        let energy: Energy = TransactionCost.TRANSFER
//        let payload: AccountTransactionPayload = AccountTransactionPayload.transfer(amount: amount, receiver: receiver, memo: memo)
//        let transaction: AccountTransaction = AccountTransaction(sender: sender, payload: payload, energy: energy)
        
        let transaction: AccountTransaction = AccountTransaction.transfer(sender: sender, receiver: receiver, amount: amount, memo: memo)
        let expiry: TransactionTime = Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
        let sequenceNumber: SequenceNumber = accountInfo.sequenceNumber
        
        let preparedAccountTransaction: PreparedAccountTransaction = transaction.prepare(sequenceNumber: sequenceNumber, expiry: expiry, signatureCount: Int(accountInfo.threshold))
    
        return try await send(preparedAccountTransaction, keys: keys)
    }
    
    func getTransactionStatus(_ transaction: TransactionHash) async throws -> TransactionStatus {
        try await nodeClient.status(transaction: transaction)
    }
    
    private func send(_ preparedAccountTransaction: PreparedAccountTransaction, keys: AccountKeys) async throws -> SubmittedTransaction {
        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeysJSON().toSDKType().keys)
        let signedAccountTransaction: SignedAccountTransaction = try signer.sign(transaction: preparedAccountTransaction)
        return try await nodeClient.send(transaction: signedAccountTransaction)
    }
    
    // MARK: Encrypted Amount calculation helpers
    func getInputEncryptedAmount(for account: AccountDataType) -> InputEncryptedAmount {
        // if existing pending transactions,
        // aggEncryptedAmount = last self amount from transaction + any incoming amounts that were NOT used in that transaction
        // else aggEncryptedAmount = selfAmount + incoming Amounts
        
        var index: Int
        let aggEncryptedAmount: String?
        
        if let encryptedBalance = account.encryptedBalance {
            
            let incomingAmounts = encryptedBalance.incomingAmounts.filter { (amount) -> Bool in
                storageManager.getShieldedAmount(encryptedValue: amount, account: account) != nil
            }
            
            // we always use all the indexes available in incoming Amounts
            index = encryptedBalance.startIndex + incomingAmounts.count
            
            // if we have any pending transactions, we calculate the amount and the index based on what was used in that transaction
            if let transaction = storageManager.getLastEncryptedBalanceTransfer(for: account.address),
               let encryptedDetails = transaction.encryptedDetails,
               let latestSelfAmount = encryptedDetails.updatedNewSelfEncryptedAmount {
                var amounts: [String] = [latestSelfAmount]
                let lastUsedIndexInTransaction = encryptedDetails.updatedNewStartIndex
                
                // get the first unused index of incoming amounts and add that to the selfAmount
                let startIndexInIncomingAmounts = lastUsedIndexInTransaction - encryptedBalance.startIndex
                if startIndexInIncomingAmounts < incomingAmounts.count {
                    amounts.append(contentsOf: incomingAmounts[startIndexInIncomingAmounts..<incomingAmounts.count])
                }
                aggEncryptedAmount = addAmounts(amounts)
            } else {
                // if we don't have any pending transactions, we just add up the incoming amounts
                var amounts: [String] = incomingAmounts
                if let selfAmount = encryptedBalance.selfAmount {
                    amounts.append(selfAmount)
                }
                aggEncryptedAmount = addAmounts(amounts)
            }
        } else {
            // this shouldn't happen
            index = 0
            aggEncryptedAmount = account.encryptedBalance?.selfAmount
        }
        let inputEncryptedAmount = InputEncryptedAmount(aggEncryptedAmount: aggEncryptedAmount,
                                                        aggAmount: String(account.forecastEncryptedBalance),
                                                        aggIndex: index)
        return inputEncryptedAmount
    }
    
    private func addAmounts(_ amounts: [String]) -> String {
        do {
            return try amounts.reduce("") { (result, amount) -> String in
                if result == "" {
                    return amount
                } else {
                    return try self.combineEncryptedAmount(result, amount).get()
                }
            }
        } catch {
            return ""
        }
    }
    
    func combineEncryptedAmount(_ encryptedAmount1: String, _ encryptedAmount2: String) -> Result<String, Error> {
        do {
            let encodedEncryptedAmount1 = "\"\(encryptedAmount1)\""
            let encodedEncryptedAmount2 = "\"\(encryptedAmount2)\""
            let combined = try combineEncryptedAmounts(left: Data(encodedEncryptedAmount1.utf8), right: Data(encodedEncryptedAmount2.utf8))
            let sumEncrypted = String(data: combined, encoding: .utf8) ?? ""
            
            let startIndex = sumEncrypted.index(sumEncrypted.startIndex, offsetBy: 1)
            let endIndex = sumEncrypted.index(sumEncrypted.startIndex, offsetBy: sumEncrypted.count - 1)
            let decodedSumEncrypted = String(sumEncrypted[startIndex..<endIndex])
            return Result.success(decodedSumEncrypted)
        } catch {
            return Result.failure(error)
        }
    }
}
