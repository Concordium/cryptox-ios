//
//  TokenUpdateRequestModel.swift
//  CryptoX
//
//  Created by Max on 15.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import BigInt
import ReownWalletKit
import Concordium

final class TokenUpdateRequestModel: SessionRequestDataProvidable {
    @Published var title: String = "Sign PLT Transfer"
    @Published var subtitle: String? = "Transfer"
    @Published var tokenBalance: String?
    @Published var validationError: String?
    @Published var isTokenValid: Bool = false
    
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let params: TokenUpdateRequestParams
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let storageManager: StorageManagerProtocol
    private let concordiumClient: ConcordiumClient
    private let pltTokenService: PLTTokenService
    
    func getFormattedMessage() -> String {
        do {
            let operations = try params.parseOperations()
            guard case let .transfer(transferPayload) = operations[0] else {
                return String(describing: sessionRequest.params.value)
            }
            
            let receiverData = transferPayload.receiver.data
            let receiverAddress = (try? AccountAddress(Data(receiverData)))?.base58Check ?? "Unknown"

            let formattedAmount = TokenFormatter.formatPLTTokenWithDecimals(
                String(transferPayload.amount.value),
                decimals: transferPayload.amount.decimals
            )
            
            var message = "**Token:** \(params.payload.tokenId)\n\n"
            message += "**Amount:** \(formattedAmount)\n\n"
            message += "**To:** \(receiverAddress)"
            
            if let memo = transferPayload.memo, memo.content.isEmpty == false,
               let memoString = memo.asString() {
                message += "\n\n**Memo:** \(memoString)"
            }
            
            return message
        } catch {
            return String(describing: sessionRequest.params.value)
        }
    }
    
    init(
        params: TokenUpdateRequestParams,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        storageManager: StorageManagerProtocol,
        concordiumClient: ConcordiumClient
    ) {
        self.sessionRequest = sessionRequest
        self.params = params
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        self.storageManager = storageManager
        self.concordiumClient = concordiumClient
        self.pltTokenService = PLTTokenService()
        
        Task {
            await fetchAndDisplayTokenBalance()
            _ = try? await checkAllSatisfy()
        }
    }
    
    @MainActor
    private func fetchAndDisplayTokenBalance() async {
        let pltService = PLTTokenService()
        
        do {
            let pltTokens = try CoreDataPLTStore.shared.fetchAccountPLTTokens(for: account.address)
            let pltTokenBalances = try await pltService.fetchTokenBalances(for: account.address)
            
            if let token = pltTokens.first(where: { $0.token.tokenId == params.payload.tokenId }) {
                let balanceEntry = pltTokenBalances.first(where: { $0.key == token.token.tokenId })
                
                if let balance = balanceEntry?.value {
                    let formattedBalance = TokenFormatter.formatPLTTokenWithDecimals(
                        balance.balance.value,
                        decimals: balance.balance.decimals
                    )
                    self.tokenBalance = "\(formattedBalance) \(params.payload.tokenId)"
                    
                    if validationError == "Token balance not found" || validationError == "Token not found or hidden" {
                        validationError = nil
                    }
                } else {
                    validationError = "Token balance not found"
                }
            } else {
                validationError = "Token not found or hidden"
            }
        } catch {
            validationError = "Failed to fetch token balance"
        }
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        // Don't reset balance - it should already be set by fetchAndDisplayTokenBalance()
        // Only reset validation error if we're re-validating
        isTokenValid = false
        
        do {
            let isValid = try await validateTokenTransfer()
            isTokenValid = isValid
            if isValid {
                validationError = nil
            }
            return isValid
        } catch let error as SessionRequstError {
            validationError = error.errorMessage
            isTokenValid = false
            return false
        } catch {
            validationError = error.localizedDescription
            isTokenValid = false
            return false
        }
    }
    
    @MainActor
    func approveRequest() async throws {
        let isValid = try await checkAllSatisfy()
        guard isValid else {
            throw SessionRequstError.generic(validationError ?? "Validation failed")
        }
        
        let operations = try params.parseOperations()
        guard case let .transfer(transferPayload) = operations[0] else {
            throw SessionRequstError.generic("Invalid operation type")
        }
        
        let token = try await getPLTToken()
        
        let pwHash = try await passwordDelegate.requestUserPassword(keychain: ServicesProvider.defaultProvider().keychainWrapper())
        guard let encryptedAccountDataKey = account.encryptedAccountData,
              let accountKeys = try? storageManager.getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get() else {
            throw SessionRequstError.generic("Failed to get account keys")
        }
        
        let receiverData = transferPayload.receiver.data
        let receiverAddress = try AccountAddress(Data(receiverData))
        
        let amount = BigDecimal(
            BigInt(transferPayload.amount.value),
            transferPayload.amount.decimals
        )
        
        var concordiumMemo: Concordium.Memo? = nil
        if let memo = transferPayload.memo {
            concordiumMemo = Concordium.Memo(Data(memo.content))
        }
        
        let result = try await concordiumClient.transferPLT(
            token: token,
            sender: try AccountAddress(base58Check: account.address),
            amount: amount,
            receiver: receiverAddress,
            keys: accountKeys,
            memo: concordiumMemo
        )
        
        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result.hash.hex]))
        )
    }
    
    @MainActor
    private func validateTokenTransfer() async throws -> Bool {
        let operations = try params.parseOperations()
        guard case let .transfer(transferPayload) = operations[0] else {
            throw SessionRequstError.generic("Invalid operation type")
        }

        var token: AccountPLTToken?

        do {
            token = try await getPLTToken()
            
            if let token = token {
                let tokenBalanceState = token.tokenAccountState

                if tokenBalance == nil {
                    let formattedBalance = TokenFormatter.formatPLTTokenWithDecimals(
                        tokenBalanceState.balance.value,
                        decimals: tokenBalanceState.balance.decimals
                    )
                    tokenBalance = "\(formattedBalance) \(params.payload.tokenId)"
                }
            }
        } catch {
            // If we can't get token or balance, set error but continue validation
            if token == nil {
                // Only set error if not already set
                if validationError == nil {
                    validationError = "Token not found or hidden"
                }
                throw error
            }
        }
        
        guard let token = token else {
            validationError = "Token not found or hidden"
            throw SessionRequstError.generic("Token not found or hidden")
        }

        if token.token.tokenState.moduleState.paused {
            validationError = "Token transfers are paused for this token"
            throw SessionRequstError.generic("Token transfers are paused for this token")
        }

        if token.token.tokenState.moduleState.allowList {
            let receiverData = transferPayload.receiver.data
            guard let receiverAddress = try? AccountAddress(Data(receiverData)) else {
                validationError = "Invalid recipient address"
                throw SessionRequstError.generic("Invalid recipient address")
            }
            
            let pltService = PLTTokenService()
            do {
                let recipientBalances = try await pltService.fetchTokenBalances(for: receiverAddress.base58Check)
                if let recipientTokenState = recipientBalances[params.payload.tokenId] {
                    if recipientTokenState.state.allowList != true {
                        validationError = "Recipient address is not in the token allow list"
                        throw SessionRequstError.generic("Recipient address is not in the token allow list")
                    }
                } else {
                    validationError = "Recipient address is not in the token allow list"
                    throw SessionRequstError.generic("Recipient address is not in the token allow list")
                }
            } catch let error as SessionRequstError {
                throw error
            } catch {
                validationError = "Unable to verify recipient is in allow list: \(error.localizedDescription)"
                throw SessionRequstError.generic("Unable to verify recipient is in allow list")
            }
        }

        let tokenBalanceState = token.tokenAccountState
        let transferAmount = BigDecimal(
            BigInt(transferPayload.amount.value),
            transferPayload.amount.decimals
        )
        let availableBalance = BigDecimal(
            BigInt(stringLiteral: tokenBalanceState.balance.value),
            tokenBalanceState.balance.decimals
        )
        
        if transferAmount.value > availableBalance.value {
            validationError = "Insufficient token balance"
            throw SessionRequstError.generic("Insufficient token balance")
        }
        
        let operation = TokenUpdateOperation.transfer(transferPayload)
        let energy = TransactionCost.pltTransferCost(tokenId: params.payload.tokenId, operation: operation)
        
        let estimatedCost = BigInt(energy) * BigInt(100)
        
        let ccdBalance = BigInt(account.forecastAtDisposalBalance)
        if estimatedCost >= ccdBalance {
            validationError = "Insufficient CCD balance to pay transaction fee"
            throw SessionRequstError.generic("Insufficient CCD balance to pay transaction fee")
        }
        
        return true
    }
    
    @MainActor
    private func getPLTToken() async throws -> AccountPLTToken {
        let pltService = PLTTokenService()
        
        let pltTokens = try CoreDataPLTStore.shared.fetchAccountPLTTokens(for: account.address)
        let pltTokenBalances = try await pltService.fetchTokenBalances(for: account.address)
        
        guard let token = pltTokens.first(where: { $0.token.tokenId == params.payload.tokenId }) else {
            throw SessionRequstError.generic("Token not found or hidden")
        }
        
        let tokenBalance = pltTokenBalances.first(where: { $0.key == token.token.tokenId })
        let fallback = TokenAccountState(
            balance: TokenBalance(decimals: Int(token.token.tokenState.decimals), value: "0"),
            state: TokenBalanceState(denyList: nil, allowList: nil)
        )
        
        guard let accountPLTToken = token.token.asPLTToken() else {
            throw SessionRequstError.generic("Failed to convert token")
        }
        
        return AccountPLTToken(
            token: accountPLTToken,
            tokenAccountState: tokenBalance?.value ?? fallback
        )
    }
}

