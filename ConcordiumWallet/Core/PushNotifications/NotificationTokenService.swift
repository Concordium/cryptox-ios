//
//  NotificationTokenService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 16.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import RealmSwift

final class NotificationTokenService {
    
    let defaultProvider = ServicesProvider.defaultProvider()
    lazy var cis2Service: CIS2Service = {
        CIS2Service(networkManager: defaultProvider.networkManager(), storageManager: defaultProvider.storageManager())
    }()

    // Parse token metadata from userInfo
    private func parseTokenMetadata(metadata: Any?) -> [String: Any] {
        (metadata as? String)
                .flatMap { $0.data(using: .utf8) }
                .flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]
                } ?? [:]
    }

    // Fetch token metadata asynchronously from a given URL
    func getTokenMetadata(with metadata: Any?) async -> CIS2TokenMetadata? {
        let dictionary = parseTokenMetadata(metadata: metadata)

        guard let tokenUrl = dictionary["url"] as? String,
              let url = URL(string: tokenUrl) else {
            print("Invalid URL")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedMetadata = try JSONDecoder().decode(CIS2TokenMetadata.self, from: data)
            return decodedMetadata
        } catch {
            print("Error fetching metadata: \(error)")
            return nil
        }
    }

    // Check if a token exists for a given contract or show alert if not
    func checkToken(from userInfo: [AnyHashable: Any], completion: @escaping (TokenResult?) -> Void) {
        guard let (contractName, contractIndex, contractSubindex, accountAddress) = extractContractDetails(from: userInfo) else {
            completion(nil)
            return
        }

        let savedTokens = defaultProvider.storageManager().getAccountSavedCIS2Tokens(accountAddress)

        if let savedToken = savedTokens.first(where: {
            $0.contractName == contractName &&
            $0.contractAddress.index == contractIndex &&
            $0.contractAddress.subindex == contractSubindex
        }) {
            Task {
                do {
                    let balance = try await cis2Service.fetchTokensBalance(contractIndex: savedToken.contractAddress.index.string, accountAddress: accountAddress, tokenId: savedToken.tokenId).first
                    if let balance {
                        completion(.tokenFound(savedToken, balance))
                    }
                } catch {
                    completion(.showAlert)
                }
            }
        } else {
            completion(.showAlert)
        }
    }

    // Store a new token based on userInfo details
    func storeNewToken(from userInfo: [AnyHashable: Any], completion: @escaping (CIS2Token, CIS2TokenBalance?) -> Void) {
        guard let (contractName, contractIndex, contractSubindex, accountAddress) = extractContractDetails(from: userInfo),
              let tokenId = userInfo["token_id"] as? String else {
            return
        }

        Task {
            do {
                let tokens = try await cis2Service.fetchAllTokensData(contractIndex: contractIndex, subindex: contractSubindex, tokenIds: tokenId)
                guard let token = tokens.first(where: { $0.contractName == contractName }) else { return }
                let balance = try await cis2Service.fetchTokensBalance(contractIndex: token.contractAddress.index.string, accountAddress: accountAddress, tokenId: token.tokenId).first
                try await MainActor.run {
                    try defaultProvider.storageManager().storeCIS2Token(token: token, address: accountAddress)
                }
                completion(token, balance)
            } catch {
                print("Error storing token: \(error.localizedDescription)")
            }
        }
    }

    // Extract contract details from the notification payload
    private func extractContractDetails(from userInfo: [AnyHashable: Any]) -> (String, Int, Int, String)? {
        guard let contractName = userInfo["contract_name"] as? String else {
            return nil
        }

        let contractData = (userInfo["contract_address"] as? String)
            .flatMap { $0.data(using: .utf8) }
            .flatMap {
                try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]
            }

        guard let contractData,
              let contractIndex = contractData["index"] as? Int,
              let contractSubindex = contractData["subindex"] as? Int,
              let accountAddress = userInfo["recipient"] as? String else {
            return nil
        }

        return (contractName, contractIndex, contractSubindex, accountAddress)
    }
}
