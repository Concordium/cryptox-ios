import Foundation
import MnemonicSwift
import Concordium


enum WalletError: Error {
    case invalidInput
    case noResponse
    case failed(String)
}

struct TokenTransferParamBox: Codable {
    let parameter: String
}

enum ConfigureBakerOrDelegation {
    case configureDelegation
    case configureBaker
}

class MobileWalletFacade {
    func serializeTokenTransferParameters(input: TokenTransferParameters) throws -> String {
        //        let response = try call(
        //            cFunction: serialize_token_transfer_parameters,
        //            with: try encodeInput(input),
        //            debugTitle: "serialize_token_transfer_parameters"
        //        )
        guard let amount = UInt64(input.amount) else { throw WalletError.invalidInput }
        let receiverAddress = try AccountAddress(base58Check: input.to)
        var transfer = AccountTransactionPayload.transfer(amount: CCD(microCCD: amount), receiver: receiverAddress, memo: nil)
        var serializedData = transfer.serialize()
        guard let serializedString = String(data: serializedData, encoding: .utf8) else { throw WalletError.noResponse }
        return serializedString
    }
    
    func createIdRequestAndPrivateData(input: CreateIDRequestV1) throws -> IDRequestV1 {
        //        let response = try call(
        //            cFunction: create_id_request_and_private_data_v1,
        //            with: try encodeInput(input),
        //            debugTitle: "createIdRequestAndPrivateDataV1"
        //        )
        let response = ""
        return try decodeOutput(IDRequestV1.self, from: response)
    }
    
    func createCredential(input: CreateSeedCredentialRequest) throws -> CreateCredentialRequest {
        //        let response = try call(
        //            cFunction: create_credential_v1,
        //            with: try encodeInput(input),
        //            debugTitle: "createCredentialV1"
        //        )
        
        let response = ""
        return try decodeOutput(CreateCredentialRequest.self, from: response)
    }
    
    func generateRecoveryRequest(input: GenerateRecoveryRequestInput) throws -> GenerateRecoveryRequestOutput {
        //        let response = try call(
        //            cFunction: generate_recovery_request,
        //            with: try encodeInput(input),
        //            debugTitle: "generateRecoveryRequest"
        //        )
        
        let response = ""
        return try decodeOutput(GenerateRecoveryRequestOutput.self, from: response)
    }
    
    func createIdRequestAndPrivateData(input: String) throws -> String {
        //        try call(cFunction: create_id_request_and_private_data, with: input, debugTitle: "createIdRequestAndPrivateData")
        return ""
    }
    
    func createCredential(input: String) throws -> String {
        //        try call(cFunction: create_credential, with: input, debugTitle: "createCredential")
        return ""
    }
    
    func createUpdateTransfer(input: String) throws -> String {
        //        try call(cFunction: create_account_transaction, with: input, debugTitle: "createUpdateTransfer")
        return ""
    }
    
    func createTransfer(input: MakeCreateTransferRequest, pwHash: String, fromAccount: AccountDataType) async throws -> String {
        //        try call(cFunction: create_transfer, with: input, debugTitle: "createTransfer")
        guard let url = URL(string: "https://grpc.testnet.concordium.com:20000") else { return "" }
        let nodeClient = try GRPCNodeClient(url: url)
        let account = try await getAccount(client: nodeClient, pwHash: pwHash, fromAccount: fromAccount)
        let amount = try CCD(input.amount ?? "")
        let receiverAddress = try AccountAddress(base58Check: input.to ?? "")
        let senderAddress = try AccountAddress(base58Check: input.from ?? "")
        let nextSeq = try await nodeClient.nextAccountSequenceNumber(address: senderAddress)
        let expiry = TransactionTime(input.expiry ?? 0)
        let signedTransaction = try makeTransfer(account, amount, receiverAddress, nextSeq.sequenceNumber, expiry)
        let submitted = try await nodeClient.send(transaction: signedTransaction)
        return ""
    }
    
    func createShielding(input: String) throws -> String {
        //        try call(cFunction: create_pub_to_sec_transfer, with: input, debugTitle: "createShielding")
        return ""
    }
    
    func createUnshielding(input: String) throws -> String {
        //        try call(cFunction: create_sec_to_pub_transfer, with: input, debugTitle: "createUnshielding")
        return ""
    }
    
    func createEncrypted(input: String) throws -> String {
        //        try call(cFunction: create_encrypted_transfer, with: input, debugTitle: "createEncrypted")
        return ""
    }
    
    func createTransaction(input: MakeCreateTransferRequest,
                           pwHash: String,
                           fromAccount: AccountDataType,
                           transactionType: ConfigureBakerOrDelegation) async throws -> String {
        guard let url = URL(string: "https://grpc.testnet.concordium.com:20000") else { return "" }
        let nodeClient = try GRPCNodeClient(url: url)
        let senderAddress = try AccountAddress(base58Check: input.from ?? "")
        
        let payload: AccountTransactionPayload
        switch transactionType {
        case .configureDelegation:
            let capital = try CCD(input.capital ?? "")
            let delegationTarget: Concordium.DelegationTarget = input.delegationTarget?.bakerID == nil
            ? .passive
            : .baker(BakerID(input.delegationTarget?.bakerID ?? 0))
            
            payload = .configureDelegation(ConfigureDelegationPayload(
                capital: capital,
                restakeEarnings: input.restakeEarnings,
                delegationTarget: delegationTarget
            ))
            
        case .configureBaker:
            let capital = try CCD(input.capital ?? "")
            payload = .configureBaker(ConfigureBakerPayload(
                capital: capital,
                openForDelegation: try .decodeFromSring(input.openStatus ?? ""),
                metadataUrl: input.metadataURL,
                transactionFeeCommission: try AmountFraction.decodeFromSring(input.transactionFeeCommission ?? ""),
                bakingRewardCommission: try AmountFraction.decodeFromSring(input.bakingRewardCommission ?? ""),
                finalizationRewardCommission: try AmountFraction.decodeFromSring(input.finalizationRewardCommission ?? "")
            ))
        }
        
        let transaction = AccountTransaction(sender: senderAddress, payload: payload, energy: UInt64(input.energy ?? 0))
        let account = try await getAccount(client: nodeClient, pwHash: pwHash, fromAccount: fromAccount)
        let nextSeq = try await nodeClient.nextAccountSequenceNumber(address: senderAddress)
        let expiry = TransactionTime(input.expiry ?? 0)
        
        let signedTransaction = try account.keys.sign(transaction: transaction, sequenceNumber: nextSeq.sequenceNumber, expiry: expiry)
        let submitted = try await nodeClient.send(transaction: signedTransaction)
        
        print("Transaction with hash '\(submitted.hash.hex)' successfully submitted.")
        return submitted.hash.hex
    }
    
    func getAccount(client: NodeClient, pwHash: String, fromAccount: AccountDataType) async throws -> Account {
        let seedPhrase = try await ServicesProvider.defaultProvider().seedMobileWallet().getSeed(pwHash: pwHash)
        let seed = try decodeSeed(seedPhrase.value, .testnet)
        
        let cryptoParams = try await client.cryptographicParameters(block: .lastFinal)
        let accountDerivation = SeedBasedAccountDerivation(seed: seed, cryptoParams: cryptoParams)
        
        guard let providerId = fromAccount.identity?.identityProvider?.ipInfo?.ipIdentity,
              let identityIndex = fromAccount.identity?.index,
              let counter = fromAccount.identity?.accountsCreated else {
            throw MobileWalletError.invalidArgument
        }
        
        let credentialIndexes = AccountCredentialSeedIndexes(
            identity: .init(providerID: IdentityProviderID(providerId), index: IdentityIndex(identityIndex)),
            counter: CredentialCounter(counter)
        )
        
        return try accountDerivation.deriveAccount(credentials: [credentialIndexes])
    }
    
    // Seed Decoding Utility
    public func decodeSeed(_ seedPhrase: String, _ network: Network) throws -> WalletSeed {
        let seedHex = try Mnemonic.deterministicSeedString(from: seedPhrase)
        return try WalletSeed(seedHex: seedHex, network: network)
    }
    
    
    /// Construct and sign transfer transaction.
    func makeTransfer(
        _ account: Account,
        _ amount: CCD,
        _ receiver: AccountAddress,
        _ seq: SequenceNumber,
        _ expiry: TransactionTime
    ) throws -> SignedAccountTransaction {
        let tx = AccountTransaction.transfer(sender: account.address, receiver: receiver, amount: amount)
        return try account.keys.sign(transaction: tx, sequenceNumber: seq, expiry: expiry)
    }
    
    func generateBakerKeys() throws -> String {
        let bakerKeys = BakerKeyPairs.generate()
        return bakerKeys.toString()
    }
    
    func decryptEncryptedAmount(input: String) throws -> Int {
        
        //         try callIntFunction(cFunction: decrypt_encrypted_amount, with: input, debugTitle: "decryptEncryptedAmount")
        return 0
    }
    
    func combineEncryptedAmounts(input1: String, input2: String) throws -> String {
        //           try callTwoParameterFunction(cFunction: combine_encrypted_amounts, with: input1, andWith: input2, debugTitle: "combineEncryptedAmounts")
        return ""
    }
    
    func checkAccountAddress(input: String) -> Bool {
        //        input.withCString { inputPointer in
        //            let response = check_account_address(inputPointer)
        //            return response > 0
        //        }
        return true
    }
    
    func generateAccounts(input: String) throws -> String {
        //        try call(cFunction: generate_accounts, with: input, debugTitle: "generateAccounts")
        return ""
    }
    
    func signMessage(input: SignMessagePayloadToJsonInput) throws -> String {
        //        try call(cFunction: sign_message, with: try encodeInput(input), debugTitle: "signMessage")
        return ""
    }
    
    private func call(cFunction: (UnsafePointer<Int8>?, UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<Int8>?,
                      with input: String,
                      debugTitle: String) throws -> String {
        LegacyLogger.debug("TX \(debugTitle):\n\(input)")
        var responseString = ""
        try input.withCString { inputPointer in
            var returnCode: UInt8 = 0
            guard let responsePtr = cFunction(inputPointer, &returnCode) else {
                throw WalletError.noResponse
            }
            responseString = String(cString: responsePtr)
            //            free_response_string(responsePtr)
            
            guard returnCode == 1 else {
                LegacyLogger.error("RX Error: \(responseString)")
                throw WalletError.failed(responseString)
            }
        }
        
        LegacyLogger.debug("RX \(debugTitle):\n\(responseString)")
        return responseString
        
    }
    
    private func callNoParams(cFunction: (UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<Int8>?,
                              debugTitle: String) throws -> String {
        LegacyLogger.debug("TX \(debugTitle):\n")
        var responseString = ""
        
        var returnCode: UInt8 = 0
        guard let responsePtr = cFunction(&returnCode) else {
            throw WalletError.noResponse
        }
        responseString = String(cString: responsePtr)
        //        free_response_string(responsePtr)
        
        guard returnCode == 1 else {
            LegacyLogger.error("RX Error: \(responseString)")
            throw WalletError.failed(responseString)
        }
        
        LegacyLogger.debug("RX \(debugTitle):\n\(responseString)")
        return responseString
    }
    
    private func callTwoParameterFunction(cFunction: (UnsafePointer<Int8>?,
                                                      UnsafePointer<Int8>?,
                                                      UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<Int8>?,
                                          with input1: String,
                                          andWith input2: String,
                                          debugTitle: String) throws -> String {
        LegacyLogger.debug("TX \(debugTitle):\n\(input1)\n\(input2)")
        var responseString = ""
        try input1.withCString { inputPointer1 in
            try input2.withCString { inputPointer2 in
                var returnCode: UInt8 = 0
                guard let responsePtr = cFunction(inputPointer1, inputPointer2, &returnCode) else {
                    throw WalletError.noResponse
                }
                responseString = String(cString: responsePtr)
                //                free_response_string(responsePtr)
                
                guard returnCode == 1 else {
                    LegacyLogger.error("RX Error: \(responseString)")
                    throw WalletError.failed(responseString)
                }
            }
        }
        LegacyLogger.debug("RX \(debugTitle):\n\(responseString)")
        return responseString
        
    }
    
    private func callIntFunction(cFunction: (UnsafePointer<Int8>?, UnsafeMutablePointer<UInt8>?) -> UInt64?,
                                 with input: String,
                                 debugTitle: String) throws -> Int {
        LegacyLogger.debug("TX \(debugTitle):\n\(input)")
        var response: UInt64?
        try input.withCString { inputPointer in
            var returnCode: UInt8 = 0
            response = cFunction(inputPointer, &returnCode)
            
            if response == nil {
                throw WalletError.noResponse
            }
        }
        
        guard let uintResponse = response else {
            throw WalletError.failed("RX: Empty integeer value")
        }
        let intResponse = Int(uintResponse)
        LegacyLogger.debug("RX \(debugTitle):\n\(intResponse)")
        return intResponse
        
    }
    
    private let encoder = newJSONEncoder()
    
    private func encodeInput<Input: Encodable>(_ input: Input) throws -> String {
        let data = try encoder.encode(input)
        
        guard let stringData = String(data: data, encoding: .utf8) else {
            throw WalletError.invalidInput
        }
        
        return stringData
    }
    
    private let decoder = newJSONDecoder()
    
    private func decodeOutput<Output: Decodable>(_ outputType: Output.Type, from string: String) throws -> Output {
        guard let data = string.data(using: .utf8) else {
            throw WalletError.noResponse
        }
        
        return try decoder.decode(outputType, from: data)
    }
}
