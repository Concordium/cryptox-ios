//
//  AppDelegate.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Base58Swift
import FirebaseMessaging
import FirebaseCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    weak var window: UIWindow?
    var appCoordinator: AppCoordinator = AppCoordinator(/*walletConnectService: WalletConnectService()*/)
    let transactionNotificationService = TransactionNotificationService()
    
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Listen for application timeout.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.receivedApplicationTimeout),
                                               name: .didReceiveAppTimeout,
                                               object: nil)
        
        UIApplication.shared.statusBarStyle = .lightContent
                
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        transactionNotificationService.subscribeToUserDefaultsUpdates()
        Messaging.messaging().delegate = self

        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            transactionNotificationService.handleNotificationsWithData(data: remoteNotification)
        }
        
        return true
    }
    
    /// Checks if the given URL string matches a specified URL scheme pattern.
    /// - Parameters:
    ///  - url: The URL string to be checked.
    ///     - Returns:
    ///        - `true` if the URL string matches the specified pattern, otherwise `false`.
    ///     - Note:
    ///       The function checks if the provided `url` matches one of two patterns:
    ///       1. The URL scheme specified by the `ApiConstants.scheme` constant, followed by "://wc".
    ///       2. The exact URL scheme "concordiumwallet" followed by "://wc".
    ///       The reason for these check is that we want to check if url follows `concordiumwallet` scheme for WalletConnect,
    ///       but need to support also DeepLinks per scheme, for instance `concordiumwallettest` or  `concordiumwalletstaging`
    private func matchesURLScheme(_ url: String) -> Bool {
        let regexPattern = #"^\#(ApiConstants.scheme)://wc.*|concordiumwallet://wc.*|cryptox://wc.*|cryptoxtestnet://wc.*|cryptoxstage://wc.*"#
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else { return false }
        let range = NSRange(location: 0, length: url.utf16.count)
        if let match = regex.firstMatch(in: url, options: [], range: range) {
            return match.range == range
        }
        return false
    }

    func handleOpenURL(_ url: URL) {
        logger.debugLog("openUrl: \(url)")

        
        if url.absoluteString.starts(with: ApiConstants.notabeneCallback) {
            receivedCreateIdentityCallback(url)
        } else if matchesURLScheme(url.absoluteString) {
            appCoordinator.openWCConnect(url)
        } else if let scheme = url.scheme, scheme.localizedCaseInsensitiveCompare("tcwb") == .orderedSame, let _ = url.host {
            
            var parameters: [String: String] = [:]
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
            
            if let url = parameters["uri"] {
                appCoordinator.mode = .deepLink(url: url)
                appCoordinator.handle(url)
            }
        } else if let scheme = url.scheme, scheme.localizedCaseInsensitiveCompare("file") == .orderedSame {
            // importing file - only handle file:// URLs
            appCoordinator.importWallet(from: url)
        }
        // Removed the fallback else case to prevent handling regular deep links as file imports
    }
}

extension AppDelegate {
    func receivedCreateIdentityCallback(_ url: URL) {
        let url = url.absoluteString
        NotificationCenter.default.post(name: .didReceiveIdentityData, object: url)
    }
    
    @objc func receivedApplicationTimeout() {
        appCoordinator.logout()
    }
    
    @objc  func resetFlow() {
        appCoordinator.resetFlow()
    }
}


extension UIViewController {
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return (navigation.visibleViewController?.topMostViewController())!
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    /// The content window of this single-window app, excluding the privacy overlay.
    var appWindow: UIWindow? {
        (delegate as? AppDelegate)?.window
    }

    func topMostViewController() -> UIViewController? {
        return appWindow?.rootViewController?.topMostViewController()
    }
}

// MARK: - Notifications handling
extension AppDelegate: MessagingDelegate {
    @objc func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token: \(String(describing: fcmToken))")
        if UIApplication.shared.isRegisteredForRemoteNotifications {
            transactionNotificationService.updateFcmToken(fcmToken)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .list, .sound]
    }
    
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        appCoordinator.handleOpeningTransactionFromNotification(with: userInfo)
        completionHandler()
    }
}

extension AppDelegate {
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Oh no! Failed to register for remote notifications with error \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var readableToken = ""
        for index in 0 ..< deviceToken.count {
            readableToken += String(format: "%02.2hhx", deviceToken[index] as CVarArg)
        }
        print("Received an APNs device token: \(readableToken)")
        
        Messaging.messaging().apnsToken = deviceToken
        
        Messaging.messaging().token { token, error in
            if let error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token {
                print("FCM registration token: \(token)")
                self.transactionNotificationService.updateFcmToken(token)
            }
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        transactionNotificationService.handleNotificationsWithData(data: userInfo)

      return UIBackgroundFetchResult.newData
    }
}
