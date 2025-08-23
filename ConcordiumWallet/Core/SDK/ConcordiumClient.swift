import Foundation
import Concordium
import BigInt
import MnemonicSwift

protocol ConcordiumClientProtocol {
    // TODO: - hide this behind function
    var nodeClient: GRPCNodeClient { get }
    
    func transferCIS2(
        sender: AccountAddress,
        receiver: AccountAddress,
        keys: AccountKeys,
        contractAddress: Concordium.ContractAddress,
        tokenId: String,
        amount: BigInt
    ) async throws -> SubmittedTransaction
    
    func transferCCD(
        sender: AccountAddress,
        amount: CCD,
        receiver: AccountAddress,
        keys: AccountKeys,
        memo: Concordium.Memo?
    ) async throws -> SubmittedTransaction
    
    func transferToPublic(
        account: AccountDataType,
        amount: CCD,
        receiver: AccountAddress,
        keys: AccountKeys,
        pwHash: String
    ) async throws -> SubmittedTransaction
    
    func transferPLT(
        token: AccountPLTToken,
        sender: AccountAddress,
        amount: String,
        decimals: UInt16,
        receiver: AccountAddress,
        keys: AccountKeys,
        memo: Concordium.Memo?
    ) async throws -> SubmittedTransaction
}

final class ConcordiumClient: ObservableObject {
    static var grpcURL: URL {
#if TESTNET
        URL(string: "https://grpc.devnet-plt-beta.concordium.com:20000")!
#elseif MAINNET
        URL(string: "https://grpc.testnet.concordium.com:20000")!
#else // Staging
        URL(string: "https://grpc.stagenet.concordium.com:20000")!
#endif
    }
    
    static var network: Network {
#if TESTNET
        Network.testnet
#elseif MAINNET
        Network.mainnet
#else // Staging
        Network.testnet
#endif
    }
    
    static let walletProxyBaseURL = ApiConstants.proxyUrl
    
    var nodeClient: GRPCNodeClient
    var networkManager: NetworkManagerProtocol
    private let storageManager: StorageManagerProtocol
    private let walletProxy: WalletProxy
    
    init(networkManager: NetworkManagerProtocol, storageManager: StorageManagerProtocol) throws {
        self.nodeClient = try GRPCNodeClient(url: Self.grpcURL)
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.walletProxy = WalletProxy(baseURL: Self.walletProxyBaseURL)
    }
    
    func getAccountInfo(address: String) async throws -> AccountInfo {
        try await nodeClient.info(account: AccountIdentifier.address(.init(base58Check: address)))
    }
}

///
/// PLT
///
extension ConcordiumClient {
    func transferPLT(
        token: AccountPLTToken,
        sender: AccountAddress,
        amount: String,
        decimals: UInt16,
        receiver: AccountAddress,
        keys: AccountKeys,
        memo: Concordium.Memo?
    ) async throws -> SubmittedTransaction {
        let accountInfo = try await nodeClient.info(account: AccountIdentifier.address(sender))
        let transaction: AccountTransaction = AccountTransaction.transfer(
            plt: token.token.tokenID,
            sender: sender,
            receiver: receiver,
            amount: try Concordium.Amount(amount, decimalCount: decimals),
            memo: memo)
        
        let expiry: TransactionTime = Self.calculateTransactionExpiry(from: UInt64(Date().timeIntervalSince1970))
        let sequenceNumber: SequenceNumber = accountInfo.sequenceNumber
        
        let preparedAccountTransaction: PreparedAccountTransaction = transaction.prepare(sequenceNumber: sequenceNumber, expiry: expiry, signatureCount: Int(accountInfo.threshold))
        
        return try await send(preparedAccountTransaction, keys: keys)
    }
}

///
/// Wallet Connect Sign Logic
///
///
@MainActor
extension ConcordiumClient {    
    func proveStatements(
        statements: [AtomicIdentityStatement],
        seedPhrase: String,
        account: AccountEntity
    ) async throws -> IdentityProof {
        let walletSeed = try Helper.decodeSeed(seedPhrase, ConcordiumClient.network)
        let cryptoParams = try await nodeClient.cryptographicParameters(block: .lastFinal)
        let credentialIndices = AccountCredentialSeedIndexes(
            identity: IdentitySeedIndexes(
                providerID: IdentityProviderID(account.identity?.identityProvider?.ipInfo?.ipIdentity ?? 0),
                index: IdentityIndex(account.identity?.index ?? 0)),
            counter: CredentialCounter(account.identityEntity?.accountsCreated ?? 0)
        )
        

        //TODO: - handle legacy file-based account
        guard let identityObjectApp = account.identityEntity?.seedIdentityObject else { throw GeneralAppError.somethingWentWrong }
        
        guard let data = try identityObjectApp.json().data(using: .utf8) else { throw GeneralAppError.somethingWentWrong }
        
        let identityObject = try JSONDecoder().decode(Concordium.IdentityObject.self, from: data)
        return IdentityProof(proofs: try IdentityStatement(statements: statements)
            .prove(
                wallet: walletSeed,
                global: cryptoParams,
                credentialIndices: credentialIndices,
                identityObject: identityObject,
                challenge: Data()
            ).value.proofs)
    }
}

///
/// CIS-2 Token
///
extension ConcordiumClient: ConcordiumClientProtocol {
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
        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeyDictionary())
        
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
    
    private func send(_ preparedAccountTransaction: PreparedAccountTransaction, keys: AccountKeys) async throws -> SubmittedTransaction {
        let signer: any Signer = AccountKeysCurve25519.init(try keys.toAccountKeyDictionary())
        let signedAccountTransaction: SignedAccountTransaction = try signer.sign(transaction: preparedAccountTransaction)
        return try await nodeClient.send(transaction: signedAccountTransaction)
    }
    
    // MARK: - Encrypted Amount calculation helpers
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



import Concordium

// Helpers
extension ConcordiumClient {
    /// - Parameter expiry: The transaction expiry in seconds since Unix epoch.
    static func calculateTransactionExpiry(from expiry: TransactionTime) -> TransactionTime {
        // Adding 10 minutes (600 seconds) to the expiry
        let tenMinutesInSeconds: TransactionTime = 600
        return expiry + tenMinutesInSeconds
    }
}

