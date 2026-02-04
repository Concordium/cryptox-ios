//
//  SponsoredTransactionRequestModel.swift
//  CryptoX
//
//  Created on 2026.
//  Copyright © 2026 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import ReownWalletKit
import Concordium
import CryptoKit
import GRPC
import BigInt

final class SponsoredTransactionRequestModel: SessionRequestDataProvidable {
    @Published var title: String = "Sign Transaction"
    @Published var subtitle: String? = "Sponsored Transaction"
    
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let params: SponsoredTransactionRequestParams
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let storageManager: StorageManagerProtocol
    private let concordiumClient: ConcordiumClient
    private let networkManager: NetworkManagerProtocol
    
    init(
        params: SponsoredTransactionRequestParams,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        storageManager: StorageManagerProtocol,
        concordiumClient: ConcordiumClient,
        networkManager: NetworkManagerProtocol
    ) {
        self.sessionRequest = sessionRequest
        self.params = params
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        self.storageManager = storageManager
        self.concordiumClient = concordiumClient
        self.networkManager = networkManager
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        // Extract Realm values to local variables before async operations
        let accountAddressString = account.address
        let accountBalance = UInt64(account.forecastAtDisposalBalance) ?? 0
        
        // Use SDK validation helper
        let accountAddress = try AccountAddress(base58Check: accountAddressString)
        
        // Check if this is a PLT transfer and fetch token balance if needed
        var tokenBalance: BigUInt? = nil
        do {
            let payload = try AccountTransaction.decodePayload(from: params.payload)
            if case .updatePLT(let tokenId, let operation) = payload {
                if case .transfer = operation {
                    // Fetch token balance for PLT transfer validation
                    tokenBalance = try await fetchTokenBalance(tokenId: tokenId, accountAddress: accountAddressString)
                }
            }
        } catch {
            // If we can't decode payload, validation will catch it
        }
        
        do {
            _ = try SponsoredTransactionValidator.validate(
                headerHex: params.header,
                payloadHex: params.payload,
                expectedSender: accountAddress,
                accountBalance: accountBalance,
                tokenBalance: tokenBalance
            )
            return true
        } catch let error as ValidationError {
            throw SessionRequstError.generic(error.localizedDescription)
        } catch let error as DeserializeError {
            throw SessionRequstError.generic("Invalid transaction data: \(error.localizedDescription)")
        } catch {
            throw SessionRequstError.generic("Failed to validate transaction: \(error.localizedDescription)")
        }
    }
    
    /// Fetch token balance for a given token ID
    /// - Parameters:
    ///   - tokenId: The token ID to fetch balance for
    ///   - accountAddress: The account address (extracted from Realm object to avoid threading issues)
    private func fetchTokenBalance(tokenId: String, accountAddress: String) async throws -> BigUInt? {
        let pltService = PLTTokenService()
        let tokenBalances = try await pltService.fetchTokenBalances(for: accountAddress)
        
        guard let tokenState = tokenBalances[tokenId],
              let balanceValue = BigUInt(tokenState.balance.value) else {
            return nil
        }
        
        return balanceValue
    }
    
    @MainActor
    func approveRequest() async throws {
        do {
            // Get account keys
            let pwHash = try await passwordDelegate.requestUserPassword(keychain: ServicesProvider.defaultProvider().keychainWrapper())
            guard let encryptedAccountDataKey = account.encryptedAccountData,
                  let accountKeys = try? storageManager.getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get() else {
                throw SessionRequstError.generic("Failed to get account keys")
            }
            
            // Use SDK builder to create and sign sponsored transaction
            let accountAddress = try AccountAddress(base58Check: account.address)
            let accountKeyDict = try accountKeys.toAccountKeyDictionary()
            let signer: any Signer = AccountKeysCurve25519(accountKeyDict)
            
            // Extract Realm values to local variables before async operations
            let accountAddressString = account.address
            let accountBalanceValue = UInt64(account.forecastAtDisposalBalance) ?? 0
            
            // Check if this is a PLT transfer and fetch token balance if needed
            var tokenBalance: BigUInt? = nil
            do {
                let payload = try AccountTransaction.decodePayload(from: params.payload)
                if case .updatePLT(let tokenId, let operation) = payload {
                    if case .transfer = operation {
                        // Fetch token balance for PLT transfer validation
                        tokenBalance = try await fetchTokenBalance(tokenId: tokenId, accountAddress: accountAddressString)
                    }
                }
            } catch {
                // If we can't decode payload, validation will catch it
            }
            
            let signedSponsoredTransaction = try SponsoredTransactionBuilder.createAndSign(
                headerHex: params.header,
                payloadHex: params.payload,
                sponsorSignatureHex: params.sponsorSignature,
                signer: signer,
                expectedSender: accountAddress,
                accountBalance: accountBalanceValue,
                tokenBalance: tokenBalance
            )
            
            // Serialize as V1 block item (preserves sponsor information)
            let rawBlockItemBytes = signedSponsoredTransaction.serializeAsBlockItem()
            
            // Compute transaction hash from the raw bytes
            let transactionHash = Data(SHA256.hash(data: rawBlockItemBytes))
            let hashHex = transactionHash.map { String(format: "%02x", $0) }.joined()
            
            // Submit via wallet-proxy - this preserves the V1 format
            let submissionResponse: SubmissionResponse = try await submitRawTransaction(rawBlockItemBytes)
            
            // Respond to WalletConnect with the transaction hash
            try await Sign.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .response(AnyCodable(any: ["hash": hashHex]))
            )
        } catch let error as SessionRequstError {
            // Re-throw SessionRequstError as-is
            throw error
        } catch let error as ValidationError {
            // Convert SDK validation errors
            throw SessionRequstError.generic(error.localizedDescription)
        } catch let error as DeserializeError {
            // Convert SDK deserialization errors
            throw SessionRequstError.generic("Invalid transaction data: \(error.localizedDescription)")
        } catch let error as GRPCStatus {
            // Convert GRPC errors to user-friendly messages
            let errorMessage: String
            switch error.code {
            case .unavailable:
                errorMessage = "Unable to connect to the node. Please check your internet connection."
            case .deadlineExceeded:
                errorMessage = "Request timed out. Please try again."
            case .invalidArgument:
                // Include the detailed error message for invalid transactions
                let details = error.message?.isEmpty == false ? error.message! : "Please check the transaction details."
                errorMessage = "Invalid transaction: \(details)"
            case .failedPrecondition:
                errorMessage = "Transaction cannot be processed at this time."
            case .notFound:
                errorMessage = "Transaction not found on the node."
            case .permissionDenied:
                errorMessage = "Permission denied. Please check your account permissions."
            case .resourceExhausted:
                errorMessage = "Node is currently overloaded. Please try again later."
            case .aborted:
                errorMessage = "Transaction was aborted. Please try again."
            case .outOfRange:
                errorMessage = "Transaction parameters are out of valid range."
            case .unimplemented:
                errorMessage = "This operation is not supported by the node."
            case .unauthenticated:
                errorMessage = "Authentication failed. Please check your credentials."
            case .cancelled:
                errorMessage = "Request was cancelled."
            default:
                let details = error.message?.isEmpty == false ? error.message! : error.localizedDescription
                errorMessage = "Network error: \(details)"
            }
            throw SessionRequstError.generic(errorMessage)
        } catch {
            // Convert any other errors to a user-friendly message
            throw SessionRequstError.generic("Failed to process sponsored transaction: \(error.localizedDescription)")
        }
    }
    
    /// Submit raw transaction bytes via wallet-proxy
    /// This preserves the V1 transaction format with sponsor information
    private func submitRawTransaction(_ transactionBytes: Data) async throws -> SubmissionResponse {
        let url = ApiConstants.submitRawTransaction
        
        // Create a custom request with application/octet-stream content type
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = transactionBytes
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add cookies and language headers (matching ResourceRequest behavior)
        // Note: We need to merge with existing headers, not replace them
        var headers = HTTPCookie.requestHeaderFields(with: CookieJar.cookies)
        let deviceLanguageCode = NSLocale.current.identifier
        headers["Accept-Language"] = deviceLanguageCode
        headers["Content-Type"] = "application/octet-stream"
        headers["Accept"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        // Submit the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SessionRequstError.generic("Invalid response from wallet-proxy")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                LegacyLogger.error("RX \(httpResponse.statusCode) \(url):\n\(errorMessage)")
                throw SessionRequstError.generic("Wallet-proxy submission failed (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            // Parse the submission response
            let decoder = JSONDecoder()
            let submissionResponse = try decoder.decode(SubmissionResponse.self, from: data)
            return submissionResponse
        } catch {
            LegacyLogger.error("Failed to submit sponsored transaction: \(error)")
            throw error
        }
    }
}

