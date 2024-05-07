//
//  AppDelegate.swift
//  ConcordiumWallet
//
//  Created by Concordium on 05/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Base58Swift
import Web3Wallet

extension Notification.Name {
    static let didReceiveIdentityData = Notification.Name("didReceiveIdentityData")
}

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appCoordinator = AppCoordinator()
    
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
                
        configure()
        
        
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
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        logger.debugLog("application:openUrl: \(url)")

        
        if url.absoluteString.starts(with: ApiConstants.notabeneCallback) {
            receivedCreateIdentityCallback(url)
        } else if url.host == "wc" {
            appCoordinator.openWCConnect(url)
        } else if let scheme = url.scheme, scheme.localizedCaseInsensitiveCompare("tcwb") == .orderedSame, let view = url.host {
            
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
    func configure() {
        Networking.configure(projectId: "f64859abcbf5c1de9520a27399f3097c", socketFactory: DefaultSocketFactory())

        let metadata = AppMetadata(
            name: "CryptoX",
            description: "CryptoX - Blockchain Wallet",
            url: "https://apps.apple.com/app/cryptox-wallet/id1593386457",
            icons: ["https://is2-ssl.mzstatic.com/image/thumb/Purple122/v4/d2/76/4f/d2764f4a-cb11-2039-7edf-7bb1a7ea36d8/AppIcon-1x_U007emarketing-0-5-0-sRGB-85-220.png/230x0w.png"]
        )
        
        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: APNSEnvironment.sandbox)
    }
}

struct DefaultCryptoProvider: CryptoProvider {

    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
      Data()
    }

    public func keccak256(_ data: Data) -> Data { Data()
//        let digest = SHA3(variant: .keccak256)
//        let hash = digest.calculate(for: [UInt8](data))
//        return Data(hash)
    }
}
