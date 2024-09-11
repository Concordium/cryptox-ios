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

enum NotificationTypes: String {
    case cis2 = "cis2-tx"
    case ccd = "ccd-tx"
}

protocol NotificationNavigationDelegate: AnyObject {
    func openTransactionFromNotification(with userInfo: [AnyHashable: Any])
}

final class TransactionNotificationService {
    
    private var cancellables = Set<AnyCancellable>()
    let defaultProvider = ServicesProvider.defaultProvider()
    private var currentFcmToken: String?

    init() {
        subscribeToUserDefaultsUpdates()
    }
    
    func configureFirebase() {
        #if MAINNET
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info-Mainnet", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
        } else {
            fatalError("Couldn't load GoogleService-Info-Mainnet.plist")
        }
        #elseif TESTNET
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info-Testnet", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
        } else {
            fatalError("Couldn't load GoogleService-Info-Testnet.plist")
        }
        #endif
    }
    
    func sendTokenToConcordiumServer(fcmToken: String?) {
       guard let fcmToken,
             let url = URL(string: AppConstants.Notifications.baseUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var preferences = [String]()

        if let isCIS2TransactionNotificationAllowed = UserDefaults().value(forKey: "isCIS2TransactionNotificationAllowed") as? Bool,
           isCIS2TransactionNotificationAllowed {
            preferences.append(NotificationTypes.cis2.rawValue)
        }
        if let isCCDTransactionNotificationAllowed = UserDefaults().value(forKey: "isCCDTransactionNotificationAllowed") as? Bool,
           isCCDTransactionNotificationAllowed{
            preferences.append(NotificationTypes.ccd.rawValue)
        }
        let accounts = defaultProvider.storageManager().getAccounts().map({$0.address})
        
        let body: [String : Any] = [
            "preferences": preferences,
            "accounts": accounts,
            "device_token": fcmToken
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error subscribing to Concordium server: \(error)")
                return
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully subscribed to Concordium notification server")
            }
        }
        task.resume()
    }
    
    func updateFcmToken(_ newToken: String?) {
        currentFcmToken = newToken
        sendTokenToConcordiumServer(fcmToken: newToken)
    }
    
    private func subscribeToUserDefaultsUpdates() {
        UserDefaults.standard.publisher(for: "isCCDTransactionNotificationAllowed")
            .merge(with: UserDefaults.standard.publisher(for: "isCIS2TransactionNotificationAllowed"))
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.sendTokenToConcordiumServer(fcmToken: self?.currentFcmToken)
                }
            }
            .store(in: &cancellables)
    }
    
    func handleNotificationsWithData(data: [AnyHashable: Any]) {
        if let type = data["type"] as? String {
            if type == NotificationTypes.ccd.rawValue {
                handleCCDTransactionNotifications(data: data)
            } else if type == NotificationTypes.cis2.rawValue {
                handleCIS2TransactionNotifications(data: data)
            }
        }
    }
    
    
    private func handleCCDTransactionNotifications(data: [AnyHashable: Any]) {
        let amount = data["amount"] as? String ?? ""
        let content = UNMutableNotificationContent()
        content.title = "You received \(amount) CCDs"
        content.body = "notifications.seeTransactionDetails".localized
        content.sound = UNNotificationSound.default
        content.userInfo = data
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "ccdNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    private func handleCIS2TransactionNotifications(data: [AnyHashable: Any]) {
        let amount = data["amount"] as? String ?? ""
        let content = UNMutableNotificationContent()
        content.title = "You received \(amount) EURe"
        content.body = "notifications.seeTransactionDetails".localized
        content.sound = UNNotificationSound.default
        content.userInfo = data
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "cis2Notifications", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}
