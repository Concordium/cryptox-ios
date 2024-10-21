//
//  TransactionNotificationService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import FirebaseCore
import Combine
import UIKit
import BigInt

enum TransactionNotificationTypes: String {
    case cis2 = "cis2-tx"
    case ccd = "ccd-tx"
}

enum TokenResult {
    case tokenFound(CIS2Token)
    case showAlert
}

enum TransactionNotificationNames: String {
    case cis2 = "isCIS2TransactionNotificationAllowed"
    case ccd = "isCCDTransactionNotificationAllowed"
}

protocol NotificationNavigationDelegate: AnyObject {
    func openTransactionFromNotification(with userInfo: [AnyHashable: Any])
}

protocol TransactionNotificationServiceDelegate: AnyObject {
    func presentTokenAlert(userInfo: [AnyHashable: Any], completion: @escaping (CIS2Token) -> Void)
}

final class TransactionNotificationService {
    
    private var cancellables = Set<AnyCancellable>()
    let defaultProvider = ServicesProvider.defaultProvider()
    private var currentFcmToken: String?
    weak var delegate: TransactionNotificationServiceDelegate?

    func sendTokenToConcordiumServer() {
        guard let preferences = getTransactionNotificationPreferences(), !preferences.isEmpty else {
            sendRequest(createRequest(isSubscribe: false))
            return
        }
        
        sendRequest(createRequest(isSubscribe: true, preferences: preferences))
    }

    private func getTransactionNotificationPreferences() -> [String]? {
        let cis2Allowed = UserDefaults().bool(forKey: TransactionNotificationNames.cis2.rawValue)
        let ccdAllowed = UserDefaults().bool(forKey: TransactionNotificationNames.ccd.rawValue)
        
        return [cis2Allowed ? TransactionNotificationTypes.cis2.rawValue : nil,
                ccdAllowed ? TransactionNotificationTypes.ccd.rawValue : nil]
            .compactMap { $0 }
    }

    private func sendRequest(_ request: URLRequest?) {
        guard let request = request else { return }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                logger.errorLog("Error subscribing to Concordium server: \(error)")
                return
            }
        }.resume()
    }

    private func createRequest(isSubscribe: Bool, preferences: [String] = []) -> URLRequest? {
        guard let currentFcmToken,
              let url = URL(string: AppConstants.Notifications.baseUrl + (isSubscribe ? AppConstants.Notifications.subscribe : AppConstants.Notifications.unsubscribe)) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = isSubscribe ? "PUT" : "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = isSubscribe ? [
            "preferences": preferences,
            "accounts": defaultProvider.storageManager().getAccounts().map { $0.address },
            "device_token": currentFcmToken
        ] : [
            "device_token": currentFcmToken
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    
    func updateFcmToken(_ newToken: String?) {
        guard newToken != currentFcmToken else { return }
        currentFcmToken = newToken
        sendTokenToConcordiumServer()
    }
    
    func handleCCDTransaction(account: AccountDataType, transactionId: String, accountDetailRouter: AccountDetailsCoordinator, completion: @escaping ((TransactionViewModel)-> Void)) {
        let transactionLoadingHandler = TransactionsLoadingHandler(account: account, balanceType: .balance, dependencyProvider: defaultProvider)
        
        transactionLoadingHandler.getTransactions()
            .map { transactions in
                return transactions.1.first(where: { $0.details.transactionHash == transactionId })
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error loading transactions: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { transaction in
                if let transaction = transaction {
                    completion(transaction)
                } else {
                    print("Transaction not found")
                }
            })
            .store(in: &cancellables)
    }
    
    func handleCIS2Notification(userInfo: [AnyHashable: Any], account: AccountDataType, navigationController: UINavigationController) {
        let detailRouter = AccountDetailRouter(account: account, navigationController: navigationController, dependencyProvider: defaultProvider)
        
        guard let result = NotificationTokenService().checkToken(from: userInfo) else { return }
        switch result {
        case .tokenFound(let token):
            detailRouter.showCIS2TokenDetailsFlow(token, account: account)
        case .showAlert:
            delegate?.presentTokenAlert(userInfo: userInfo) { token in
                DispatchQueue.main.async {
                    detailRouter.showCIS2TokenDetailsFlow(token, account: account)
                }
            }
        }
    }
    
    func subscribeToUserDefaultsUpdates() {
        UserDefaults.standard.publisher(for: TransactionNotificationNames.cis2.rawValue)
            .merge(with: UserDefaults.standard.publisher(for: TransactionNotificationNames.ccd.rawValue))
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.sendTokenToConcordiumServer()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: Helper methods
extension TransactionNotificationService {
    private func parseTokenMetadata(metadata: Any?) -> [String: Any] {
        (metadata as? String)
                .flatMap { $0.data(using: .utf8) }
                .flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: []) as? [String: Any]
                } ?? [:]
    }
    
    private func getTokenMetadata(with metadata: Any?) async -> CIS2TokenMetadata? {
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

    
    private func composeAndSendNotification(title: String, userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "notifications.seeTransactionDetails".localized
        content.sound = UNNotificationSound.default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "transactionNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}

extension TransactionNotificationService {
    /// `CIS2Token` send payload example
    /*
     {
       "elements": [
         {
           "key": "aps",
           "value": {
             "content-available": 1
           }
         },
         {
           "key": "contract_name",
           "value": "CIS2-TOKEN"
         },
         {
           "key": "google.c.fid",
           "value": "eaLv4EKdbE1To6esWIGsJ3"
         },
         {
           "key": "token_id",
           "value": ""
         },
         {
           "key": "recipient",
           "value": "2z623igvSJVHxHq1kAdE28yNVPP31MSu57MXcR1Vj8Z15eqdUH"
         },
         {
           "key": "google.c.sender.id",
           "value": "124880082147"
         },
         {
           "key": "gcm.message_id",
           "value": "1729500340736196"
         },
         {
           "key": "contract_address",
           "value": {
             "index": 4514,
             "subindex": 0
           }
         },
         {
           "key": "type",
           "value": "cis2-tx"
         },
         {
           "key": "token_metadata",
           "value": {
             "url": "https://test-metadata.concordex.io/ETH",
             "hash": null
           }
         },
         {
           "key": "amount",
           "value": 100000000000000000000
         },
         {
           "key": "reference",
           "value": "e110ae8cc284b7f7c7b968e026de76ff97ba860cf185a10e9a57f47b1aec8da5"
         }
       ]
     }

     */
    
    ///
    /// Pay attention, for NFT `decimals` will be nill, thats why we should add this fallback: `metadata.decimals ?? 0`
    ///
    /// https://proposals.concordium.software/CIS/cis-2.html#token-metadata-json
    ///
    
    func handleNotificationsWithData(data: [AnyHashable: Any]) {
        let amount = data["amount"] as? String ?? ""
        
        if let type = data["type"] as? String,
           type == TransactionNotificationTypes.cis2.rawValue,
           let tokenMetadata = data["token_metadata"] {
            Task {
                guard let metadata = await getTokenMetadata(with: tokenMetadata) else {
                    return
                }
                let symbol = metadata.symbol ?? ""
                let formattedAmount = TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: amount), metadata.decimals ?? 0))
                
                self.composeAndSendNotification(
                    title: "You received \(formattedAmount) \(symbol)",
                    userInfo: data
                )
            }
        } else {
            let symbol = "CCDs"
            let formattedAmount = TokenFormatter().string(from: BigDecimal(BigInt(stringLiteral: amount), 6))
            self.composeAndSendNotification(
                title: "You received \(formattedAmount) \(symbol)",
                userInfo: data
            )
        }
    }
}
