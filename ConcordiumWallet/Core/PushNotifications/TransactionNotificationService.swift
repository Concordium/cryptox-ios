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
    private var previousCIS2Value: Any?
    private var previousCCDValue: Any?
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
                print("Error subscribing to Concordium server: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully subscribed to Concordium notification server")
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
    
    func handleNotificationsWithData(data: [AnyHashable: Any]) {
        let amount = data["amount"] as? String ?? ""
        
        if let type = data["type"] as? String,
           type == TransactionNotificationTypes.cis2.rawValue,
           let tokenMetadata = data["token_metadata"] {
            Task {
                guard let metadata = await NotificationTokenService().getTokenMetadata(with: tokenMetadata) else {
                    return
                }
                let symbol = metadata.symbol ?? "Unknown Token"
                self.composeAndSendNotification(amount: amount, symbol: symbol, data: data)
            }
        } else {
            let symbol = "CCDs"
            composeAndSendNotification(amount: amount, symbol: symbol, data: data)
        }
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
        
        Task {
            guard let result = await NotificationTokenService().checkToken(from: userInfo) else { return }
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
    }
    
    func subscribeToUserDefaultsUpdates() {
        UserDefaults.standard.publisher(for: TransactionNotificationNames.cis2.rawValue)
            .merge(with: UserDefaults.standard.publisher(for: TransactionNotificationNames.ccd.rawValue))
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Check if the values have changed
                    if let cis2Value = UserDefaults.standard.value(forKey: TransactionNotificationNames.cis2.rawValue),
                       cis2Value as? NSObject != self.previousCIS2Value as? NSObject {
                        self.previousCIS2Value = cis2Value
                        self.sendTokenToConcordiumServer()
                    }

                    if let ccdValue = UserDefaults.standard.value(forKey: TransactionNotificationNames.ccd.rawValue),
                       ccdValue as? NSObject != self.previousCCDValue as? NSObject {
                        self.previousCCDValue = ccdValue
                        self.sendTokenToConcordiumServer()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: Helper methods
extension TransactionNotificationService {
    private func composeAndSendNotification(amount: String, symbol: String, data: [AnyHashable: Any]) {
        var formattedAmount: String = amount
        let intAmount = Int(BigInt(stringLiteral: amount))
        formattedAmount = GTU(intValue: intAmount).displayValue()
        let content = UNMutableNotificationContent()
        content.title = "You received \(formattedAmount) \(symbol)"
        content.body = "notifications.seeTransactionDetails".localized
        content.sound = UNNotificationSound.default
        content.userInfo = data
        
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
