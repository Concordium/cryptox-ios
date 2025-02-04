//
//  AppDelegate.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Base58Swift
import MatomoTracker
import FirebaseMessaging
import FirebaseCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator = AppCoordinator(/*walletConnectService: WalletConnectService()*/)
    let transactionNotificationService = TransactionNotificationService()
    
    let gcmMessageIDKey = "gcm.message_id"

    private lazy var backgroundWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = LaunchScreenFactory.create()
        window.windowLevel = .alert
        return window
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        window?.rootViewController = appCoordinator.navigationController
        window?.makeKeyAndVisible()
        
        // Warn if device is jail broken.
        if  let url = launchOptions?[.url] as? URL, let scheme = url.scheme, scheme.localizedCaseInsensitiveCompare("tcwb") == .orderedSame, let view = url.host {
            
            var parameters: [String: String] = [:]
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
            
            if let url = parameters["uri"] {
                appCoordinator.mode = .deepLink(url: url)
            }
            
            self.appCoordinator.start()
            
        } else if UIDevice.current.isJailBroken {
            let ac = UIAlertController(title: "Warning", message: "error", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "errorAlert.okButton".localized, style: .default) { (_) in
                self.appCoordinator.start()
            }
            ac.addAction(okAction)
            appCoordinator.navigationController.present(ac, animated: true)
        } else {
            appCoordinator.start()
        }
        
        // Listen for application timeout.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.receivedApplicationTimeout),
                                               name: .didReceiveAppTimeout,
                                               object: nil)
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        setupMatomoTracker()
        
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

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        logger.debugLog("application:openUrl: \(url)")

        
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
        } else {
            // importing file
            appCoordinator.importWallet(from: url)
        }
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        backgroundWindow.isHidden = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        backgroundWindow.isHidden = true

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
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}

extension AppDelegate {
    func setupMatomoTracker() {
        
        MatomoTracker.shared.startNewSession()
        
        var debug: String {
            #if DEBUG
                return "(debug)"
            #else
                return ""
            #endif
        }
        
        var version: String {
            #if MAINNET
            if UserDefaults.bool(forKey: "demomode.userdefaultskey".localized) == true {
                return AppSettings.appVersion + " " + AppSettings.buildNumber + " " + debug
            }
            return AppSettings.appVersion
            #else
            return AppSettings.appVersion + " " + AppSettings.buildNumber + " " + debug
            #endif
        }
        
        MatomoTracker.shared.track(view: ["home", "version and network"])
        
        MatomoTracker.shared.setDimension(version, forIndex: AppConstants.MatomoTracker.versionCustomDimensionId)
        MatomoTracker.shared.setDimension(Net.current.rawValue, forIndex: AppConstants.MatomoTracker.networkCustomDimensionId)
        MatomoTracker.shared.isOptedOut = !UserDefaults.bool(forKey: "isAnalyticsEnabled")
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
