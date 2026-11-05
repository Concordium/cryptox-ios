import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var privacyWindow: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = appDelegate.appCoordinator.navigationController
        self.window = window
        appDelegate.window = window
        window.makeKeyAndVisible()

        let privacyWindow = UIWindow(windowScene: windowScene)
        privacyWindow.rootViewController = LaunchScreenFactory.create()
        privacyWindow.windowLevel = .alert
        self.privacyWindow = privacyWindow

        let start = {
            appDelegate.appCoordinator.start()
            for context in connectionOptions.urlContexts {
                appDelegate.handleOpenURL(context.url)
            }
            if let response = connectionOptions.notificationResponse {
                let userInfo = response.notification.request.content.userInfo
                appDelegate.appCoordinator.handleOpeningTransactionFromNotification(with: userInfo)
            }
        }

        if UIDevice.current.isJailBroken {
            let alert = UIAlertController(title: "Warning", message: "error", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "errorAlert.okButton".localized, style: .default) { _ in
                start()
            })
            appDelegate.appCoordinator.navigationController.present(alert, animated: true)
        } else {
            start()
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        for context in URLContexts {
            appDelegate.handleOpenURL(context.url)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Cover the content before UIKit captures the app-switcher snapshot.
        privacyWindow?.isHidden = false
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        privacyWindow?.isHidden = false
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        privacyWindow?.isHidden = true
    }
}
