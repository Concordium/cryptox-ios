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
    func createAccount(keys: AccountKeys) async throws {
        let signer: any Signer = AccountKeysCurve25519(try keys.toAccountKeysJSON().toSDKType().keys)
    }
//    func createAccount(keys: AccountKeys) async throws {
//        // Step 1: Fetch identity providers
//        let identityProviders = try await nodeClient.identityProviders()
//        guard let firstIdentityProvider = identityProviders.first else {
//            throw NSError(domain: "No identity providers found", code: -1, userInfo: nil)
//        }
//
//        // Step 2: Initialize the signer
//        let signer: any Signer = AccountKeysCurve25519(try keys.toAccountKeysJSON().toSDKType().keys)
//
//        // Step 3: Prepare the account credential
//        let accountCredential = try prepareAccountCredential(identityProvider: firstIdentityProvider)
//
//        // Step 4: Prepare the credential deployment
//        let preparedAccountCredentialDeployment = try accountCredential.prepareDeployment(
//            expiry: calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
//        )
//
//        // Step 5: Sign the credential deployment
//        let signatures = try signCredentialDeployment(preparedAccountCredentialDeployment, signer: signer)
//
//        // Step 6: Create the signed credential deployment
//        let signedAccountCredentialDeployment = SignedAccountCredentialDeployment(
//            deployment: preparedAccountCredentialDeployment,
//            signatures: signatures
//        )
//
//        // Step 7: Serialize the signed credential deployment
//        let serializedSignedAccountCredentialDeployment = try signedAccountCredentialDeployment.serialize()
//
//        // Step 8: Send the deployment to the Concordium node
//        try await nodeClient.send(deployment: serializedSignedAccountCredentialDeployment)
//    }
//
//    // Helper function to prepare the account credential
//    private func prepareAccountCredential(identityProvider: IdentityProvider) throws -> AccountCredential {
//        // Replace placeholders with actual values
//        let arData: [UInt32: ChainArData] = [:] // Add actual AR data
//        let credId: Bytes = [] // Add actual credential ID
//        let credentialPublicKeys: CredentialPublicKeys = CredentialPublicKeys(keys: [:]) // Add actual public keys
//        let ipIdentity: UInt32 = identityProvider.ipIdentity // Use the identity provider's ID
//        let policy: Policy = .init(createdAt: Date(), validTo: Date()) // Replace with actual policy
//        let proofs: Proofs = [] // Add actual proofs
//        let revocationThreshold: UInt8 = 1 // Replace with actual revocation threshold
//
//        return AccountCredential(
//            arData: arData,
//            credId: credId,
//            credentialPublicKeys: credentialPublicKeys,
//            ipIdentity: ipIdentity,
//            policy: policy,
//            proofs: proofs,
//            revocationThreshold: revocationThreshold
//        )
//    }
//
//    // Helper function to sign the credential deployment
//    private func signCredentialDeployment(
//        _ deployment: PreparedAccountCredentialDeployment,
//        signer: any Signer
//    ) throws -> CredentialSignatures {
//        // Replace placeholders with actual signatures
//        let signatures: [KeyIndex: Data] = [:] // Add actual signatures
//        return CredentialSignatures(dictionaryLiteral: signatures)
//    }
//
//    // Helper function to calculate the transaction expiry
//    private func calculateTransactionExpiry(from timestamp: UInt64) -> UInt64 {
//        // Set expiry to 1 hour from now
//        return timestamp + 3600
//    }
}
///
//extension ConcordiumClient {
//    func text(seedHex: String, ipIdentity: Concordium.IdentityProvider) throws {
//        let hdWallet = try Concordium.WalletSeed(seedHex: seedHex, network: .testnet)
// 
//        Concordium.accountcre
//    }
//    
//    
//    /**
//     * Creates the serialized input for requesting an identity recovery.
//     * @param wallet the wallet for the seed phrase that the identity should be created with
//     * @param provider the chosen identity provider
//     * @param global the global cryptographic parameters of the current chain
//     * @return returns the recovery request as a JSON string
//     */
////    func createRecoveryRequest(
////        wallet: ConcordiumHdWallet,
////        provider: IdentityProvider,
////        global: CryptographicParameters
////    ) -> String {
////        val providerIndex = provider.ipInfo.ipIdentity
////        val idCredSec = wallet.getIdCredSec(providerIndex.value, Constants.IDENTITY_INDEX)
////
////        val input = IdentityRecoveryRequestInput.builder()
////            .globalContext(global)
////            .ipInfo(provider.ipInfo)
////            .idCredSec(idCredSec)
////            .timestamp(java.time.Instant.now().epochSecond)
////            .build()
////
////        return createIdentityRecoveryRequest(input)
////    }
//    
//    
//        /*    func createIDRequest(
//         for identitiyProvider: IdentityProviderDataType,
//         index: Int,
//         globalValues: GlobalWrapper,
//         seed: Seed
//     ) -> Result<IDRequestV1, Error> {
//         guard let createRequset = CreateIDRequestV1(
//             identityProvider: identitiyProvider,
//             global: globalValues,
//             seed: seed,
//             net: .current,
//             identityIndex: index
//         ) else {
//             return .failure(MobileWalletError.invalidArgument)
//         }
//         
//         return Result {
//             try walletFacade.createIdRequestAndPrivateData(input: createRequset)
//         }
//     }*/
//    
//    func createAccount(
////        ipInfo: IPInfo,
////        arsInfos: [String : ArsInfo],
////        globalWrapper: GlobalWrapper,
////        seed: Seed,
//        keys: AccountKeys
//    ) async throws {
////        let globalWrapper: Global = try await networkManager.load(ResourceRequest(url: ApiConstants.global))
////        let global: Global = Global(
////            generator: globalWrapper.generator,
////            onChainCommitmentKey: globalWrapper.genesisString,
////            bulletproofGenerators: globalWrapper.bulletproofGenerators,
////            genesisString: globalWrapper.genesisString
////        )
////        let createIDRequest: CreateIDRequest = CreateIDRequest(
////            ipInfo: ipInfo,
////            arsInfos: arsInfos,
////            global: global
////        )
//////
//////        
////        let seed: WalletSeed = try WalletSeed(seedHex: seed.value, network: .testnet)
////        let cryptoParams: CryptographicParameters = CryptographicParameters(onChainCommitmentKey: <#T##Bytes#>, bulletproofGenerators: <#T##Bytes#>, genesisString: <#T##String#>)
////        let seedBasedAccountDerivation = SeedBasedAccountDerivation(seed: seed, cryptoParams: cryptoParams)
////        
////        let createCredentialRequest: CreateCredentialRequest = CreateCredentialRequest(
////            accountAddress: <#T##String#>,
////            accountKeys: <#T##AccountKeys#>,
////            credential: <#T##Credential#>,
////            commitmentsRandomness: <#T##CommitmentsRandomness#>,
////            encryptionPublicKey: <#T##String#>,
////            encryptionSecretKey: <#T##String#>
////        )
////        
////        
////        let credDeploiyement = AccountCredential(arData: <#T##[UInt32 : ChainArData]#>, credId: <#T##Bytes#>, credentialPublicKeys: <#T##CredentialPublicKeys#>, ipIdentity: <#T##UInt32#>, policy: <#T##Policy#>, proofs: <#T##Proofs#>, revocationThreshold: <#T##UInt8#>)
//        
//        
//        
//        
//        
//
//        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeysJSON().toSDKType().keys)
//
////        PreIdentityObject - MAYBE SOME HERE
//        let accountCredential: AccountCredential = AccountCredential(
//            arData: <#T##[UInt32 : ChainArData]#>,
//            credId: <#T##Bytes#>,
//            credentialPublicKeys: <#T##CredentialPublicKeys#>,
//            ipIdentity: <#T##UInt32#>,
//            policy: <#T##Policy#>,
//            proofs: <#T##Proofs#>,
//            revocationThreshold: <#T##UInt8#>
//        )
//        let signatures: CredentialSignatures = CredentialSignatures.init(dictionaryLiteral: <#T##(KeyIndex, Data)...##(KeyIndex, Data)#>)
//        let preparedAccountCredentialDeployment: PreparedAccountCredentialDeployment  = accountCredential.prepareDeployment(expiry: Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970)))
//        let signedAccountCredentialDeployment: SignedAccountCredentialDeployment = SignedAccountCredentialDeployment(deployment: preparedAccountCredentialDeployment, signatures: signatures)
//        let serializedSignedAccountCredentialDeployment: SerializedSignedAccountCredentialDeployment = try signedAccountCredentialDeployment.serialize()
//        try await nodeClient.send(deployment: serializedSignedAccountCredentialDeployment)
//    }
//}

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
