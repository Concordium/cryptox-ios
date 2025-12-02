//
//  NotificationTokenService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 16.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import UserNotifications

// MARK: - NotificationTokenService

final class NotificationTokenService {

    // MARK: Dependencies

    private let provider: ServicesProvider
    private lazy var cis2Service = CIS2Service(
        networkManager: provider.networkManager(),
        storageManager: provider.storageManager()
    )

    private lazy var pltService = PLTTokenService()

    // MARK: Init

    init(provider: ServicesProvider = .defaultProvider()) {
        self.provider = provider
    }

    // MARK: Public API

    /// Parse and fetch token metadata from the `metadata` payload URL (if present).
    func getTokenMetadata(with metadata: Any?) async -> CIS2TokenMetadata? {
        let dict = Self.parseJSONDictionary(from: metadata)
        guard let urlString = dict["url"] as? String, let url = URL(string: urlString) else {
            log("getTokenMetadata: invalid or missing URL in metadata")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(CIS2TokenMetadata.self, from: data)
        } catch {
            log("getTokenMetadata: fetch/decode failed: \(error)")
            return nil
        }
    }

    /// Check if a token from a notification already exists, otherwise ask UI to show an alert to add it.
    func checkToken(from userInfo: [AnyHashable: Any], completion: @escaping (TokenResult?) -> Void) {
        guard let type = TransactionNotificationTypes(rawValue: userInfo[Key.type] as? String ?? "") else {
            completion(nil)
            return
        }

        switch type {
        case .cis2:
            checkCIS2Token(from: userInfo, completion: completion)
        case .plt:
            checkPLTToken(from: userInfo, completion: completion)
        default:
            completion(nil)
        }
    }

    /// Store a new token based on notification payload and return an `AccountDetailAccount` for UI.
    func storeNewToken(from userInfo: [AnyHashable: Any], completion: @escaping (AccountDetailAccount) -> Void) {
        guard let type = TransactionNotificationTypes(rawValue: userInfo[Key.type] as? String ?? "") else {
            return
        }

        switch type {
        case .cis2:
            storeNewCIS2Token(from: userInfo, completion: completion)
        case .plt:
            storeNewPLTtoken(from: userInfo, completion: completion)
        default:
            break
        }
    }

    func areNotificationsAllowed() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - CIS2

    private func storeNewCIS2Token(
        from userInfo: [AnyHashable: Any],
        completion: @escaping (AccountDetailAccount) -> Void
    ) {
        guard
            let details = extractContractDetails(from: userInfo),
            let tokenId = userInfo[Key.tokenId] as? String
        else { return }

        let (contractName, contractIndex, contractSubindex, accountAddress) = details

        Task {
            do {
                // Fetch contract's token(s) and pick the one that matches contractName
                let tokens = try await cis2Service.fetchAllTokensData(
                    contractIndex: contractIndex,
                    subindex: contractSubindex,
                    tokenIds: tokenId
                )
                guard let token = tokens.first(where: { $0.contractName == contractName }) else {
                    log("storeNewCIS2Token: no token matched contractName=\(contractName)")
                    return
                }

                let balance = try await cis2Service
                    .fetchTokensBalance(
                        contractIndex: token.contractAddress.index.string,
                        accountAddress: accountAddress,
                        tokenId: token.tokenId
                    )
                    .first

                do {
                    try await MainActor.run {
                        try provider.storageManager().storeCIS2Token(token: token, address: accountAddress)
                    }
                } catch {
                    log("storeNewCIS2Token: store failed: \(error)")
                }

                let accountToken = AccountDetailAccount.token(
                    token: token,
                    amount: balance?.balance ?? "0.00"
                )
                completion(accountToken)
            } catch {
                log("storeNewCIS2Token: \(error)")
            }
        }
    }

    private func checkCIS2Token(
        from userInfo: [AnyHashable: Any],
        completion: @escaping (TokenResult?) -> Void
    ) {
        guard let details = extractContractDetails(from: userInfo) else {
            completion(nil)
            return
        }

        let (contractName, contractIndex, contractSubindex, accountAddress) = details
        let saved = provider.storageManager().getAccountSavedCIS2Tokens(accountAddress)

        guard let savedToken = saved.first(where: {
            $0.contractName == contractName &&
            $0.contractAddress.index == contractIndex &&
            $0.contractAddress.subindex == contractSubindex
        }) else {
            completion(.showAlert)
            return
        }

        Task {
            do {
                let balance = try await cis2Service
                    .fetchTokensBalance(
                        contractIndex: savedToken.contractAddress.index.string,
                        accountAddress: accountAddress,
                        tokenId: savedToken.tokenId
                    )
                    .first

                if let balance {
                    let accountToken = AccountDetailAccount.token(
                        token: savedToken,
                        amount: balance.balance
                    )
                    completion(.tokenFound(accountToken))
                } else {
                    completion(.showAlert)
                }
            } catch {
                log("checkCIS2Token: \(error)")
                completion(.showAlert)
            }
        }
    }

    // MARK: - PLT

    private func storeNewPLTtoken(
        from userInfo: [AnyHashable: Any],
        completion: @escaping (AccountDetailAccount) -> Void
    ) {
        guard
            let tokenId = userInfo[Key.tokenId] as? String,
            let recipient = userInfo[Key.recipient] as? String
        else { return }

        Task {
            do {
                guard let token = await pltService.fetchTokenInfoWithMetadata(for: [tokenId]).first?.pltToken,
                      let balanceEntry = try await pltService.fetchTokenBalances(for: tokenId).first?.value else {
                    log("storeNewPLTtoken: no balance for tokenId=\(tokenId)")
                    return
                }

                let accountPLTToken = AccountPLTToken(token: token, tokenAccountState: balanceEntry)
                CoreDataPLTStore.shared.saveTokens([accountPLTToken], for: recipient)

                let amount = TokenFormatter.formatPLTTokenWithDecimals(
                    balanceEntry.balance.value,
                    decimals: Int(balanceEntry.balance.decimals)
                )

                let accountToken = AccountDetailAccount.plt(token: accountPLTToken, amount: amount, metadata: nil)
                completion(accountToken)
            } catch {
                log("storeNewPLTtoken: \(error)")
            }
        }
    }

    private func checkPLTToken(
        from userInfo: [AnyHashable: Any],
        completion: @escaping (TokenResult?) -> Void
    ) {
        guard
            let tokenId = userInfo[Key.tokenId] as? String,
            let recipient = userInfo[Key.recipient] as? String
        else {
            completion(nil)
            return
        }

        do {
            let savedTokens = try CoreDataPLTStore.shared.fetchAccountPLTTokens(for: recipient)

            guard let saved = savedTokens.first(where: { $0.token.tokenId == tokenId }) else {
                completion(.showAlert)
                return
            }

            Task {
                do {
                    guard let entry = try await pltService.fetchTokenBalances(for: recipient).first(where: {$0.key == tokenId})?.value else {
                        await MainActor.run {
                            completion(.showAlert)
                        }
                        return
                    }

                    let accPLTToken = AccountPLTToken.makeToken(from: saved)
                    let amount = TokenFormatter.formatPLTTokenWithDecimals(
                        entry.balance.value,
                        decimals: Int(entry.balance.decimals)
                    )

                    let accountToken = AccountDetailAccount.plt(token: accPLTToken, amount: amount, metadata: nil)
                    await MainActor.run {
                        completion(.tokenFound(accountToken))
                    }
                } catch {
                    log("checkPLTToken: \(error)")
                    await MainActor.run {
                        completion(.showAlert)
                    }
                }
            }
        } catch {
            log("checkPLTToken (fetch saved): \(error)")
            completion(.showAlert)
        }
    }

    // MARK: - Helpers

    /// Extract contract details from the notification payload.
    private func extractContractDetails(from userInfo: [AnyHashable: Any]) -> (name: String, index: Int, subindex: Int, account: String)? {
        let addressDict = Self.parseJSONDictionary(from: userInfo[Key.contractAddress])
        guard
            let name = userInfo[Key.contractName] as? String,
            let index = addressDict["index"] as? Int,
            let subindex = addressDict["subindex"] as? Int,
            let account = userInfo[Key.recipient] as? String
        else { return nil }

        return (name, index, subindex, account)
    }

    /// Safe JSON parsing from either a JSON string or already-decoded dictionary.
    private static func parseJSONDictionary(from any: Any?) -> [String: Any] {
        if let dict = any as? [String: Any] { return dict }
        if let str = any as? String, let data = str.data(using: .utf8) {
            return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        }
        return [:]
    }

    private func log(_ msg: String) {
        print("[NotificationTokenService] \(msg)")
    }

    // MARK: - Keys

    private enum Key {
        static let type             = "type"
        static let tokenId          = "token_id"
        static let recipient        = "recipient"
        static let contractName     = "contract_name"
        static let contractAddress  = "contract_address" // JSON string with index/subindex
    }
}
