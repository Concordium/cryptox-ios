//
//  PushNotificationService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import FirebaseCore

enum NotificationPreferences: String {
    case cis2 = "cis2-tx"
    case ccd = "ccd-tx"
}

final class PushNotificationService {
    
    static var shared = PushNotificationService()
    
    let defaultProvider = ServicesProvider.defaultProvider()

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
             let url = URL(string: "https://notification-api.testnet.concordium.com/api/v1/subscription") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var preferences = [String]()

        if let isCIS2TransactionNotificationAllowed = UserDefaults().value(forKey: "isCIS2TransactionNotificationAllowed") as? Bool,
           isCIS2TransactionNotificationAllowed {
            preferences.append(NotificationPreferences.cis2.rawValue)
        }
        if let isCCDTransactionNotificationAllowed = UserDefaults().value(forKey: "isCCDTransactionNotificationAllowed") as? Bool,
           isCCDTransactionNotificationAllowed{
            preferences.append(NotificationPreferences.ccd.rawValue)
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
}
