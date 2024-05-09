//
//  AppCoordinator.swift
//  ConcordiumWallet
//
//  Created by Concordium on 13/03/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import UIKit
import Combine
import SwiftUI

import WalletConnectPairing
import Web3Wallet

@MainActor
class AppCoordinator: NSObject, Coordinator, ShowAlert, RequestPasswordDelegate {
    
    enum Mode {
        case standart
        case deepLink(url: String)
    }
    
    var mode: Mode = .standart
    var childCoordinators = [Coordinator]()

    var navigationController: UINavigationController
    let defaultProvider = ServicesProvider.defaultProvider()
    private var cancellables: [AnyCancellable] = []
    private var sanityChecker: SanityChecker
    private var accountsCoordinator: AccountsCoordinator?
    
    private var isMainFlowActive: Bool = false
    var appStartOpenURLAction: AppStartOpenURLAction = .none
    enum AppStartOpenURLAction {
        case none
        case openWalletConnect(URL)
    }
    
    private let defaultCIS2TokenManager: DefaultCIS2TokenManager
    
    @AppStorage("isRestoredDefaultCIS2Tokens") private var isRestoredDefaultCIS2Tokens = false
    @AppStorage("isAcceptedPrivacy") private var isAcceptedPrivacy = false

    override init() {
        navigationController = CXNavigationController()
        sanityChecker = SanityChecker(mobileWallet: defaultProvider.mobileWallet(), storageManager: defaultProvider.storageManager())
        self.defaultCIS2TokenManager = .init(storageManager: defaultProvider.storageManager())
        
        super.init()
        sanityChecker.coordinator = self
        sanityChecker.errorDisplayer = self
    }
    
    func start() {
        if isNewAppInstall() {
            clearAppDataFromPreviousInstall()
        }

        AppSettings.hasRunBefore = true
        showLogin()
    }
    
    private func isNewAppInstall() -> Bool {
        return !AppSettings.hasRunBefore
    }

    private func clearAppDataFromPreviousInstall() {
        let keychain = defaultProvider.keychainWrapper()
        _ = keychain.deleteKeychainItem(withKey: KeychainKeys.password.rawValue)
        _ = keychain.deleteKeychainItem(withKey: KeychainKeys.loginPassword.rawValue)
        try? defaultProvider.seedMobileWallet().removeSeed()
        try? defaultProvider.seedMobileWallet().removeRecoveryPhrase()
    }
    
    private func onboardingDone() {
        defaultProvider.storageManager().removeAccountsWithoutAddress()
        
        let identities = defaultProvider.storageManager().getIdentities()
        let accounts = defaultProvider.storageManager().getAccounts()
        
        if !accounts.isEmpty || !identities.isEmpty {
            showMainTabbar()
        } else {
            showInitialIdentityCreation()
        }
        // Remove login from hierarchy.
        self.navigationController.viewControllers = [self.navigationController.viewControllers.last!]
        childCoordinators.removeAll {$0 is LoginCoordinator}
    }
    
//    createNewAccount()
    private func showNewOnboardingFlow() {
        navigationController.popViewController(animated: false)
        navigationController.setViewControllers([UIHostingController(
            rootView:
                OnboardingRootView(
                    keychain: .init(),
                    identitiesService: defaultProvider.seedIdentitiesService(),
                    defaultProvider: defaultProvider,
                    onIdentityCreated: { [weak self] in
                        self?.onboardingDone()
                    },
                    onAccountInported: { [weak self] in
                        self?.onboardingDone()
                    },
                    onLogout: { [weak self] in
                        self?.logoutAccounts()
                    }
                )
                .environmentObject(sanityChecker)
        )], animated: false)
        navigationController.setNavigationBarHidden(true, animated: false)
    }
    
    private func createNewSeedAccount() {
        let seedIdentitiesCoordinator = SeedIdentitiesCoordinator(
            navigationController: CXNavigationController(),
            action: .createAccount,
            dependencyProvider: defaultProvider,
            delegate: self
        )

        childCoordinators.append(seedIdentitiesCoordinator)
        seedIdentitiesCoordinator.start()
        navigationController.presentedViewController?.present(seedIdentitiesCoordinator.navigationController, animated: true)
    }
    

    private func showLogin() {
        let identities = defaultProvider.storageManager().getIdentities()
        let accounts = defaultProvider.storageManager().getAccounts()
        
        navigationController.popViewController(animated: false)
        
        
        if !accounts.isEmpty || !identities.isEmpty {
            navigationController.setViewControllers([UIHostingController(
                rootView:
                    PasscodeView(keychain: defaultProvider.keychainWrapper(), sanityChecker: sanityChecker) { _ in
                        self.showMainTabbar()
                    }
            )], animated: false)
        } else {
            if defaultProvider.keychainWrapper().passwordCreated()  {
                navigationController.setViewControllers([UIHostingController(
                    rootView:
                        PasscodeView(keychain: defaultProvider.keychainWrapper(), sanityChecker: sanityChecker) { _ in
                            self.showNewOnboardingFlow()
                        }
                )], animated: false)
            } else {
                self.showNewOnboardingFlow()
            }
                
        }
    }

    func showMainTabbar() {
        let accountsCoordinator = AccountsCoordinator(
            navigationController: CXNavigationController(),
            dependencyProvider: defaultProvider,
            appSettingsDelegate: self,
            walletConnectService: WalletConnectService()
        )
        self.accountsCoordinator = accountsCoordinator
        
        let collectionsCoordinator = CollectionsCoordinator(navigationController: CXNavigationController(),
                                                      dependencyProvider: defaultProvider)
        
        let moreCoordinator = MoreCoordinator(navigationController: CXNavigationController(),
                                              dependencyProvider: defaultProvider,
                                              parentCoordinator: self
        )
        
        let tabBarController = MainTabBarController(accountsCoordinator: accountsCoordinator,
                                                    collectionsCoordinator: collectionsCoordinator,
                                                    moreCoordinator: moreCoordinator,
                                                    accountsMainRouter: .init(dependencyProvider: defaultProvider, walletConnectService: .init())
                                )
        self.navigationController.setNavigationBarHidden(true, animated: false)
        self.navigationController.pushViewController(tabBarController, animated: true)
        
        self.isMainFlowActive = true
        self.handleOpenURLActionIfNeeded()
        
        self.defaultCIS2TokenManager.initializeDefaultValues()
    }

    func importWallet(from url: URL) {
        guard UserDefaults.standard.bool(forKey: "isAcceptedPrivacy") else {
            showErrorAlert(ViewError.simpleError(localizedReason: "import.not.accepted.privacy".localized))
            return
        }

        
        guard defaultProvider.keychainWrapper().passwordCreated() else {
            navigationController.present(UIHostingController(
                rootView:
                    PasscodeView(keychain: defaultProvider.keychainWrapper(), sanityChecker: sanityChecker) { _ in
                        self.navigationController.dismiss(animated: true) {
                            self.importWallet(from: url)
                        }
                    }
            ), animated: true)
            
            
            return
        }
        
        let importCoordinator = ImportCoordinator(navigationController: CXNavigationController(),
                                                  dependencyProvider: defaultProvider,
                                                  parentCoordinator: self,
                                                  importFileUrl: url)
        importCoordinator.navigationController.modalPresentationStyle = .fullScreen
        navigationController.present(importCoordinator.navigationController, animated: true)
        importCoordinator.navigationController.presentationController?.delegate = self
        importCoordinator.start()
        childCoordinators.append(importCoordinator)
    }
    
    func showInitialIdentityCreation() {
        if FeatureFlag.enabledFlags.contains(.recoveryCode) {
            if defaultProvider.seedMobileWallet().hasSetupRecoveryPhrase {
                showSeedIdentityCreation()
            } else {
                let recoveryPhraseCoordinator = RecoveryPhraseCoordinator(
                    dependencyProvider: defaultProvider,
                    navigationController: navigationController,
                    delegate: self
                )

                recoveryPhraseCoordinator.start()
                self.navigationController.setViewControllers([navigationController.viewControllers.last!], animated: false)
                childCoordinators.append(recoveryPhraseCoordinator)
            }
        } else {
            let initialAccountCreateCoordinator = InitialAccountsCoordinator(navigationController: navigationController,
                                                                            parentCoordinator: self,
                                                                            identitiesProvider: defaultProvider,
                                                                            accountsProvider: defaultProvider)
            initialAccountCreateCoordinator.start()
            self.navigationController.viewControllers = Array(self.navigationController.viewControllers.lastElements(1))
            childCoordinators.append(initialAccountCreateCoordinator)
        }
    }
    
    func logout() {
        self.isMainFlowActive = false
        
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.dismiss(animated: false) {
                LegacyLogger.trace("logout due to application timeout")
                self.childCoordinators.removeAll()
                self.showLogin()
            }
        }
    }
    
    func resetFlow() {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.dismiss(animated: false) {
                LegacyLogger.trace("logout due to application timeout")
                self.childCoordinators.removeAll()
                self.navigationController.viewControllers.removeAll()
                self.showLogin()
            }
        }
    }
    
    func showSeedIdentityCreation() {
        let coordinator = SeedIdentitiesCoordinator(
            navigationController: navigationController,
            action: .createInitialIdentity,
            dependencyProvider: defaultProvider,
            delegate: self
        )
        
        coordinator.start()
        
        childCoordinators.append(coordinator)
    }
    
    func checkPasswordChangeDidSucceed() {
        
        if AppSettings.passwordChangeInProgress {
            showErrorAlertWithHandler(ViewError.simpleError(localizedReason: "viewError.passwordChangeFailed".localized)) {
                // Proceed with the password change.
                self.requestUserPassword(keychain: self.defaultProvider.keychainWrapper())
                    .sink(receiveError: {[weak self] error in
                        if case GeneralError.userCancelled = error { return }
                        self?.showErrorAlert(ErrorMapper.toViewError(error: error))
                    }, receiveValue: { [weak self] newPassword in
                        
                        self?.defaultProvider.keychainWrapper().getValue(for: KeychainKeys.oldPassword.rawValue, securedByPassword: newPassword)
                            .onSuccess { (oldPassword) in
                                
                                let accounts = self?.defaultProvider.storageManager().getAccounts().filter {
                                    !$0.isReadOnly && $0.transactionStatus == .finalized
                                }
                                
                                if accounts != nil {
                                    for account in accounts! {
                                        let res = self?.defaultProvider.mobileWallet().updatePasscode(for: account,
                                                                                                      oldPwHash: oldPassword,
                                                                                                      newPwHash: newPassword)
                                        switch res {
                                        case .success:
                                            if let name = account.name {
                                                LegacyLogger.debug("successfully reencrypted account with name: \(name)")
                                            }
                                        case .failure, .none:
                                            if let name = account.name {
                                                LegacyLogger.debug("could not reencrypted account with name: \(name)")
                                            }
                                        }
                                    }
                                }
                            }

                        // Remove old password from keychain and set transaction flag false.
                        try? self?.defaultProvider.keychainWrapper().deleteKeychainItem(withKey: KeychainKeys.oldPassword.rawValue).get()
                        AppSettings.passwordChangeInProgress = false
                    }).store(in: &self.cancellables)
            }
        }
    }
    
    
    func handle(_ url: String) {
        scanAddressQr(didScanAddress: url)
    }
}

extension AppCoordinator: InitialAccountsCoordinatorDelegate {
    func finishedCreatingInitialIdentity() {
        showMainTabbar()
        // Remove InitialAccountsCoordinator from hierarchy.
        self.navigationController.viewControllers = [self.navigationController.viewControllers.last!]
        childCoordinators.removeAll {$0 is InitialAccountsCoordinator}
    }
}

extension AppCoordinator: LoginCoordinatorDelegate {
    func loginDone() {
        defaultProvider.storageManager().removeAccountsWithoutAddress()
        
        let identities = defaultProvider.storageManager().getIdentities()
        let accounts = defaultProvider.storageManager().getAccounts()
        
        if !accounts.isEmpty || !identities.isEmpty {
            showMainTabbar()
        } else {
            showInitialIdentityCreation()
        }
        // Remove login from hierarchy.
        self.navigationController.viewControllers = [self.navigationController.viewControllers.last!]
        childCoordinators.removeAll {$0 is LoginCoordinator}

        checkPasswordChangeDidSucceed()
        
        switch mode {
        case .deepLink(let url):
           scanAddressQr(didScanAddress: url)
        default: break
        }
    }

    func passwordSelectionDone() {
        showInitialIdentityCreation()
        // Remove login from hierarchy.
        self.navigationController.viewControllers = [self.navigationController.viewControllers.last!]
        childCoordinators.removeAll {$0 is LoginCoordinator}
    }
}

extension AppCoordinator: ImportCoordinatorDelegate {
    func importCoordinatorDidFinish(_ coordinator: ImportCoordinator) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is ImportCoordinator })
        
        let identities = defaultProvider.storageManager().getIdentities()
        if identities.filter({$0.state == IdentityState.confirmed || $0.state == IdentityState.pending}).first != nil {
            showMainTabbar()
        }
    }

    func importCoordinator(_ coordinator: ImportCoordinator, finishedWithError error: Error) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is ImportCoordinator })
        showErrorAlert(ErrorMapper.toViewError(error: error))
    }
}

extension AppCoordinator: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        childCoordinators.removeAll(where: { $0 is ImportCoordinator })
    }
}

extension AppCoordinator: IdentitiesCoordinatorDelegate {
    func finishedDisplayingIdentities() {}
        
    func noIdentitiesFound() {
        self.navigationController.setNavigationBarHidden(true, animated: false)
        showInitialIdentityCreation()
        childCoordinators.removeAll(where: { $0 is IdentitiesCoordinator ||  $0 is AccountsCoordinator  || $0 is MoreCoordinator })
    }
}



extension AppCoordinator: AppSettingsDelegate {
    func checkForAppSettings() {
//        guard needsAppCheck else { return }
//        needsAppCheck = false
//
//        defaultProvider.appSettingsService()
//            .getAppSettings()
//            .sink(
//                receiveCompletion: { _ in },
//                receiveValue: { [weak self] response in
//                    self?.handleAppSettings(response: response)
//                }
//            )
//            .store(in: &cancellables)
    }
    
//    private func handleAppSettings(response: AppSettingsResponse) {
//        showUpdateDialogIfNeeded(
//            appSettingsResponse: response
//        ) { action in
//            switch action {
//            case .update(let url, let forced):
//                if forced {
//                    self.handleAppSettings(response: response)
//                }
//                UIApplication.shared.open(url)
//            case .cancel:
//                break
//            }
//        }
//    }
}

extension AppCoordinator: RecoveryPhraseCoordinatorDelegate {
    func recoveryPhraseCoordinator(createdNewSeed seed: Seed) {
        showSeedIdentityCreation()
        childCoordinators.removeAll { $0 is RecoveryPhraseCoordinator }
    }
    
    func recoveryPhraseCoordinatorFinishedRecovery() {
        showMainTabbar()
        childCoordinators.removeAll { $0 is RecoveryPhraseCoordinator }
    }
}

extension AppCoordinator: SeedIdentitiesCoordinatorDelegate {
    func seedIdentityCoordinatorWasFinished(for identity: IdentityDataType) {
        showMainTabbar()
    }
}

extension AppCoordinator: AccountsCoordinatorDelegate {
    func showScanAddressQR() {}
    
    func createNewIdentity() {
        accountsCoordinator?.showCreateNewIdentity()
    }

    func createNewAccount() {
        accountsCoordinator?.showCreateNewAccount()
    }

    func showIdentities() {}
}

extension AppCoordinator {
    
    func userPerformed(action: AccountCardAction, on account: AccountDataType) {
        accountsCoordinator?.userPerformed(action: action, on: account)
    }

    func enableShielded(on account: AccountDataType) {
    }

    func noValidIdentitiesAvailable() {
    }

    func tryAgainIdentity() {
    }

    func didSelectMakeBackup() {
    }

    func didSelectPendingIdentity(identity: IdentityDataType) {
    }

    func newTermsAvailable() {
//        accountsCoordinator?.showNewTerms()
    }
    
    func showSettings() {}
}

extension AppCoordinator: MoreCoordinatorDelegate {
    func showRevealSeedPrase() {
        navigationController.present(UIHostingController(
            rootView:
                RevealSeedPhraseView(viewModel: .init(identitiesService: defaultProvider.seedIdentitiesService()))

        ), animated: true)
    }
    
    func logoutAccounts() {
        isAcceptedPrivacy = false
        isRestoredDefaultCIS2Tokens = false
        clearAppDataFromPreviousInstall()
        accountsCoordinator?.childCoordinators.removeAll()
        accountsCoordinator = nil
        childCoordinators.removeAll()
        navigationController = CXNavigationController()
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController = navigationController
        start()
    }
}

extension AppCoordinator {
    func scanAddressQr(didScanAddress address: String) {
        self.mode = .standart
        
        let url = URL(string: address)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error { return }
            guard let data = data else { return }
            
            do {
                let dataResponse = try JSONDecoder().decode(QRDataResponse.self, from: data)
                let t = try JSONSerialization.jsonObject(with: data, options: [])
                
                DispatchQueue.main.async {
                    let vc = ConnectionRequestVC.instantiate(fromStoryboard: "QRConnect") { coder in
                        return ConnectionRequestVC(coder: coder)
                    }
                    vc.accs = self.defaultProvider.storageManager().getAccounts()
                    vc.dependencyProvider = self.defaultProvider
                    vc.connectionData = dataResponse
                    vc.modalPresentationStyle = .overFullScreen
                    self.navigationController.present(vc, animated: true)
                    
                }
                
            } catch let jsonErr {
                logger.debugLog(jsonErr.localizedDescription)
            }
        }
        task.resume()
    }
}

extension AppCoordinator {
    public func openWCConnect(_ uri: URL) {
        guard isMainFlowActive else {
            self.appStartOpenURLAction = .openWalletConnect(uri)
            logger.debugLog("postponed action -- \(uri.absoluteString)")
            return
        }
        accountsCoordinator?.handlWCDeeplinkConnect(uri)
    }
}


extension AppCoordinator {
    private func handleOpenURLActionIfNeeded() {
        guard isMainFlowActive else { return }
        switch appStartOpenURLAction {
            case .none: break
            case .openWalletConnect(let url):
                logger.debugLog("openWalletConnect -- \(url.absoluteString)")
                self.openWCConnect(url)
                self.appStartOpenURLAction = .none
        }
    }
}
