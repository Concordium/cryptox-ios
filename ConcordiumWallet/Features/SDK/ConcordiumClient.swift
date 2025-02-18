//
//  ConcordiumClient.swift
//  CryptoX
//
//  Created by Max on 03.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium
import BigInt

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

///
/// Account logic
///
extension ConcordiumClient {
    func createAccount(seedHex: String) throws {
//        let createIDRequest: CreateIDRequest = CreateIDRequest(
//            ipInfo: <#T##IPInfo#>,
//            arsInfos: <#T##[String : ArsInfo]#>,
//            global: <#T##Global#>
//        )
//        
//        
//        let seed: WalletSeed = try WalletSeed(seedHex: seedHex, network: .testnet)
//        let cryptoParams: CryptographicParameters = CryptographicParameters(onChainCommitmentKey: <#T##Bytes#>, bulletproofGenerators: <#T##Bytes#>, genesisString: <#T##String#>)
//        let seedBasedAccountDerivation = SeedBasedAccountDerivation(seed: seed, cryptoParams: cryptoParams)
//        
//        let createCredentialRequest: CreateCredentialRequest = CreateCredentialRequest(
//            accountAddress: <#T##String#>,
//            accountKeys: <#T##AccountKeys#>,
//            credential: <#T##Credential#>,
//            commitmentsRandomness: <#T##CommitmentsRandomness#>,
//            encryptionPublicKey: <#T##String#>,
//            encryptionSecretKey: <#T##String#>
//        )
//        
//        
//        let credDeploiyement = AccountCredential(arData: <#T##[UInt32 : ChainArData]#>, credId: <#T##Bytes#>, credentialPublicKeys: <#T##CredentialPublicKeys#>, ipIdentity: <#T##UInt32#>, policy: <#T##Policy#>, proofs: <#T##Proofs#>, revocationThreshold: <#T##UInt8#>)
//        
//        SignedAccountCredentialDeployment(
//            deployment: credDeploiyement.prepareDeployment(expiry: Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))),
//            signatures: CredentialSignatures
//        )
//        let serializedSignedAccountCredentialDeployment: SerializedSignedAccountCredentialDeployment = SerializedSignedAccountCredentialDeployment
//        
//        Task {
//            try await nodeClient.send(deployment: serializedSignedAccountCredentialDeployment)
//        }
    }
}

///
/// CIS-2 Token
///
extension ConcordiumClient {
    func transferCIS2(
        sender: AccountAddress,
        receiver: AccountAddress,
        keys: AccountKeys,
        contractAddress: Concordium.ContractAddress,
        tokenId: String,
        amount: BigInt
    ) async throws -> SubmittedTransaction {
        let cis2Client: CIS2.Contract = try await CIS2.Contract(client: nodeClient, address: contractAddress)
        let payload: CIS2.TransferPayload = CIS2.TransferPayload.init(
            tokenId: try CIS2.TokenID(hex: tokenId) ?? .init(),
            amount: CIS2.TokenAmount(BigUInt(amount)) ?? .init(.zero)!,
            sender: Address.account(sender),
            receiver: CIS2.Receiver.account(receiver),
            data: nil
        )
        let proposal = try await cis2Client.transfer(payload, sender: sender)
        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeysJSON().toSDKType().keys)
        
        return try await proposal.send(signer: signer)
    }
}

/// CCD Transfer Logic
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
}


extension ConcordiumClient {
    func getTransactionStatus(_ transaction: TransactionHash) async throws -> TransactionStatus {
        try await nodeClient.status(transaction: transaction)
    }
}

extension ConcordiumClient {
    private func getSecretEncryptionKey(for account: AccountDataType, pwHash: String) -> Result<String, Error> {
        guard let key = account.encryptedPrivateKey else { return .failure(MobileWalletError.invalidArgument) }
        return storageManager.getPrivateEncryptionKey(key: key, pwHash: pwHash)
            .mapError { $0 as Error }
    }
    
    
    /// Internal
    func send(sender: AccountAddress, amount: CCD, receiver: AccountAddress, keys: AccountKeys, memo: Concordium.Memo?) async throws -> SubmittedTransaction {
        let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(sender))
        let transaction: AccountTransaction = AccountTransaction.transfer(sender: sender, receiver: receiver, amount: amount, memo: memo)
        let expiry: TransactionTime = Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
        let sequenceNumber: SequenceNumber = accountInfo.sequenceNumber
        let preparedAccountTransaction: PreparedAccountTransaction = transaction.prepare(sequenceNumber: sequenceNumber, expiry: expiry, signatureCount: Int(accountInfo.threshold))
    
        return try await send(preparedAccountTransaction, keys: keys)
    }
    
    private func send(_ preparedAccountTransaction: PreparedAccountTransaction, keys: AccountKeys) async throws -> SubmittedTransaction {
        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeysJSON().toSDKType().keys)
        let signedAccountTransaction: SignedAccountTransaction = try signer.sign(transaction: preparedAccountTransaction)
        return try await nodeClient.send(transaction: signedAccountTransaction)
    }
    
    // MARK: Encrypted Amount calculation helpers
    private func getInputEncryptedAmount(for account: AccountDataType) -> InputEncryptedAmount {
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
                    return try String(data: Concordium.combineEncryptedAmounts(left: Data(result.utf8), right: Data(amount.utf8)), encoding: .utf8) ?? ""
                }
            }
        } catch {
            return ""
        }
    }
}
