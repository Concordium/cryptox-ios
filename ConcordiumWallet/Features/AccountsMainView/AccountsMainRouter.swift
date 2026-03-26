//
//  AccountsMainRouter.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import ReownWalletKit

protocol AccountsMainViewDelegate: AnyObject {
    func showCreateIdentityFlow()
    func showBackupSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void)
    func showCreateAccountFlow()
    func showExportFlow()
    func showNotConfiguredAccountPopup()
    func createAccountFromOnboarding(isCreatingAccount: Binding<Bool>)
    func showSettings(_ account: AccountDataType)
    /// Handle QR scan result (address, airdrop, connect URL, WalletConnect). Called from SwiftUI scanner sheet.
    func handleScanResult(_ output: QRScannerOutput)
}

extension AccountsMainRouter: AccountsMainViewDelegate {}

final class AccountsMainRouter: ObservableObject {
    let navigationController: UINavigationController = CXNavigationController()
    
    private let dependencyProvider: ServicesProvider
    private let walletConnectService: WalletConnectService
    private let onAccountsUpdate = PassthroughSubject<Void, Never>()
    weak var configureAccountAlertDelegate: ConfigureAccountAlertDelegate?
    private let navigationManager = NavigationManager()

    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true

    /// Legacy codebase support
    var childCoordinators = [Coordinator]()
    let updateTimer = UpdateTimer()
    lazy var accountsViewModel: AccountsMainViewModel = {
        let viewModel: AccountsMainViewModel = .init(dependencyProvider: dependencyProvider, onReload: onAccountsUpdate.eraseToAnyPublisher(), walletConnectService: walletConnectService)
        return viewModel
    }()
    
    init(dependencyProvider: ServicesProvider, walletConnectService: WalletConnectService) {
        self.dependencyProvider = dependencyProvider
        self.walletConnectService = walletConnectService
        self.walletConnectService.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(handleNavBarVisibility(_:)), name: .showNavBar, object: nil)
    }
    
    func rootScene() -> UINavigationController {
        let view = HomeScreenView(viewModel: self.accountsViewModel, keychain: dependencyProvider.keychainWrapper(), identitiesService: dependencyProvider.seedIdentitiesService(), router: self)
            .environmentObject(updateTimer)
            .environmentObject(navigationManager)
        let viewController = SceneViewController(content: view)
        viewController.onAppear = {
            NotificationCenter.default.post(name: .showNavBar, object: nil, userInfo: ["isHidden": true])
        }
        navigationController.setNavigationBarHidden(true, animated: false)
        viewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab_item_home"), tag: 0)
        viewController.tabBarItem.selectedImage = UIImage(named: "tab_item_home_selected")?.withRenderingMode(.alwaysOriginal)
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }
    
    @objc private func handleNavBarVisibility(_ notification: Notification) {
        if let isHidden = notification.userInfo?["isHidden"] as? Bool {
            navigationController.setNavigationBarHidden(isHidden, animated: false)
        }
    }
    
    func showTransactionDetailFromNotifications(for account: AccountDataType, tx: TransactionDetailViewModel) {
        accountsViewModel.selectedAccount = AccountPreviewViewModel(account: account)
        navigationManager.navigate(to: .transactionDetails(transaction: tx))
    }
    
    @MainActor
    func showTokenDetailsFromNotification(for account: AccountDataType, token: AccountDetailAccount) {
        accountsViewModel.selectedAccount = AccountPreviewViewModel(account: account)
        navigationManager.navigate(to: .tokenDetails(token: token, AccountDetailViewModel(account: account)))
    }

    @MainActor
    func showSettings(_ account: AccountDataType) {
        let router = AccountDetailRouter(account: account, navigationController: navigationController, dependencyProvider: dependencyProvider)
        router.accountMainViewDelegate = self
        router.showAccountSettings(account)
    }
    
    func showExportFlow() {
        let vc = ExportFactory.create(with: ExportPresenter(
            dependencyProvider: ServicesProvider.defaultProvider(),
            requestPasswordDelegate: self,
            delegate: self
        ))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }

    @MainActor
    func showCreateAccountFlow() {
        if FeatureFlag.enabledFlags.contains(.recoveryCode) && !dependencyProvider.mobileWallet().isLegacyAccount() {
            let seedIdentitiesCoordinator = SeedIdentitiesCoordinator(
                navigationController: CXNavigationController(),
                action: .createAccount,
                dependencyProvider: dependencyProvider,
                delegate: self
            )
            childCoordinators.append(seedIdentitiesCoordinator)
            seedIdentitiesCoordinator.start()
            navigationController.present(seedIdentitiesCoordinator.navigationController, animated: true)
        } else {
            let createAccountCoordinator = CreateAccountCoordinator(navigationController: CXNavigationController(),
                                                                    dependencyProvider: dependencyProvider,
                                                                    parentCoordinator: self
            )
            childCoordinators.append(createAccountCoordinator)
            createAccountCoordinator.start()
            navigationController.present(createAccountCoordinator.navigationController, animated: true, completion: nil)
        }
    }
    
    @MainActor
    func showCreateIdentityFlow() {
        let seedIdentitiesCoordinator = SeedIdentitiesCoordinator(
            navigationController: CXNavigationController(),
            action: .createIdentity,
            dependencyProvider: dependencyProvider,
            delegate: self
        )
        
        childCoordinators.append(seedIdentitiesCoordinator)
        seedIdentitiesCoordinator.start()
        navigationController.present(seedIdentitiesCoordinator.navigationController, animated: true)
    }
    
    func showBackupSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void) {
        let view =  RevealSeedPhraseView(viewModel: .init(identitiesService: identitiesService, isBackup: true, pwHash: pwHash, onBackedUp: { phrase in
            DispatchQueue.main.async { [weak self] in
                self?.navigationController.dismiss(animated: true, completion: nil)
                // Mark that user has backed up their seedphrase
                UserDefaults.standard.set(true, forKey: "isUserMakeBackup")
            }
            completion(phrase)
        }))
        let vc = SceneViewController(content: view)
        vc.hidesBottomBarWhenPushed = true
        navigationController.present(vc, animated: true)
    }
    
    func showNotConfiguredAccountPopup() {
        configureAccountAlertDelegate?.showConfigureAccountAlert()
    }
    
    @MainActor
    func createAccountFromOnboarding(isCreatingAccount: Binding<Bool>) {
        let createAccountCoordinator = CreateAccountCoordinator(navigationController: CXNavigationController(),
                                                                dependencyProvider: dependencyProvider,
                                                                parentCoordinator: self
        )
        createAccountCoordinator.createAccount(isCreatingAccount: isCreatingAccount)
    }
}

extension AccountsMainRouter: CreateNewIdentityDelegate {
    func createNewIdentityFinished() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateIdentityCoordinator })
    }

    func createNewIdentityCancelled() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateIdentityCoordinator })
    }
}

extension AccountsMainRouter {
    private func selectedAccount() -> AccountEntity? {
        let accounts = dependencyProvider.storageManager().getAccounts()
        if let lastSelectedAccountAddress = AppSettings.lastSelectedAccountAddress {
            return accounts.first(where: { $0.address == lastSelectedAccountAddress }) as? AccountEntity
        }
        return accounts.first as? AccountEntity
    }

    func handleScanResult(_ output: QRScannerOutput) {
        switch output {
        case let .address(address):
            if let account = selectedAccount() {
                navigationManager.navigate(to: .send(account, tokenType: CXTokenType.ccd, to: address))
            }
        case .airdrop(let string), .connectURL(let string):
            handleScanAddressURL(string)
        case .walletConnectV2(let uri):
            Task { @MainActor in
                let result = await walletConnectService.pair(uri)
                switch result {
                case .success:
                    break
                case .failure(let error):
                    showWalletConnectError(error)
                }
            }
        }
    }

    private func handleScanAddressURL(_ address: String) {
        guard let requestUrl = URL(string: address) else { return }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data else { return }
            do {
                let dataResponse = try JSONDecoder().decode(QRDataResponse.self, from: data)
                DispatchQueue.main.async {
                    let vc = ConnectionRequestVC.instantiate(fromStoryboard: "QRConnect") { coder in
                        return ConnectionRequestVC(coder: coder)
                    }
                    vc.accs = self.dependencyProvider.storageManager().getAccounts()
                    vc.dependencyProvider = self.dependencyProvider
                    vc.connectionData = dataResponse
                    vc.modalPresentationStyle = .overFullScreen
                    self.navigationController.present(vc, animated: true)
                }
            } catch { }
        }
        task.resume()
    }

    public func handlWCDeeplinkConnect(_ url: URL) {
        Task { @MainActor in
            let result = await walletConnectService.pair(url.absoluteString)
            switch result {
            case .success:
                break
            case .failure(let error):
                showWalletConnectError(error)
            }
        }
    }

    private func showWalletConnectError(_ error: Error) {
        let errorMessage: String
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("expired") {
            errorMessage = "The WalletConnect pairing URI has expired. Please scan a new QR code."
        } else if errorDescription.contains("json") || errorDescription.contains("decoding") || errorDescription.contains("data") {
            errorMessage = "Invalid WalletConnect data. Please try scanning the QR code again."
        } else if errorDescription.contains("invalid") {
            errorMessage = "Invalid WalletConnect URI. Please scan a valid QR code."
        } else {
            errorMessage = "Failed to connect to WalletConnect. Please try again."
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Connection Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let top = self.navigationController.topViewController,
               !top.isBeingPresented && !top.isBeingDismissed {
                self.navigationController.present(alert, animated: true)
            }
        }
    }
}

extension AccountsMainRouter: WalletConnectServiceProtocol {
    func showSessionRequest(with request: WalletConnectSign.Request, redirectURL: String?) {
        let viewController = ClearSceneViewController(
            content: SessionRequestView(
                viewModel: .init(
                    sessionRequest: request,
                    transactionsService: self.dependencyProvider.transactionsService(),
                    storageManager: self.dependencyProvider.storageManager(), 
                    mobileWallet: self.dependencyProvider.mobileWallet(),
                    concordiumClient: self.dependencyProvider.concordiumClient(),
                    identitiesService: self.dependencyProvider.seedIdentitiesService(),
                    redirectURL: redirectURL
                ),
                onSuccess: { type, redirectURL  in
                    let verificationSuccessVC = ClearSceneViewController(content: VerificationSuccessfulView(siteName: redirectURL ?? "", type: type))
                    verificationSuccessVC.modalPresentationStyle = .overFullScreen
                    verificationSuccessVC.view.backgroundColor = .clear
                    verificationSuccessVC.additionalSafeAreaInsets = .zero
                    self.navigationController.present(verificationSuccessVC, animated: true)
                }
            )
        )
        self.navigationController.present(viewController, animated: true)
    }
    
    func showSessionProposal(with proposal: Session.Proposal, context: VerifyContext?, redirectURL: String?) {
        let viewController = ClearSceneViewController(
            content: SessionProposalView(
                viewModel: .init(
                    sessionProposal: proposal,
                    wallet: self.dependencyProvider.mobileWallet(),
                    storageManager: self.dependencyProvider.storageManager(),
                    redirectURL: redirectURL)
            )
        )
        self.navigationController.dismiss(animated: true) {
            self.navigationController.present(viewController, animated: true)
        }
    }
}


extension AccountsMainRouter: AccountDetailsDelegate {
    func accountDetailsClosed() {
        navigationController.dismiss(animated: true, completion: nil)
        if let lastOccurenceIndex = childCoordinators.lastIndex(where: { $0 is AccountDetailsCoordinator }) {
            childCoordinators.remove(at: lastOccurenceIndex)
        }
    }
    
    @MainActor
    func retryCreateAccount(failedAccount: AccountDataType) {
        navigationController.popViewController(animated: true)
        showCreateAccountFlow()
        onAccountsUpdate.send(())
    }

    func accountRemoved() {
        navigationController.popViewController(animated: true)
        onAccountsUpdate.send(())
    }
}


/// Create new account flow
/// new, seed based
extension AccountsMainRouter: SeedIdentitiesCoordinatorDelegate {
    func seedIdentityCoordinatorWasFinished(for identity: IdentityDataType) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is SeedIdentitiesCoordinator })
        
        NotificationCenter.default.post(name: Notification.Name("seedAccountCoordinatorWasFinishedNotification"), object: nil)
        onAccountsUpdate.send(())
        #warning("add here handler")
    }
    
    func seedIdentityCoordinatorDidFail(with error: IdentityRejectionError) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is SeedIdentitiesCoordinator })
    }
}

/// Create new account flow
/// old one,, legacy
extension AccountsMainRouter: CreateNewAccountDelegate {
    func createNewAccountFinished() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateAccountCoordinator })
        onAccountsUpdate.send(())
#warning("add here handler")
    }
    
    func createNewAccountCancelled() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateAccountCoordinator })
    }
}

extension AccountsMainRouter: RequestPasswordDelegate {
    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
        DummyRequestPasswordDelegate().requestUserPassword(keychain: keychain)
    }
}

extension AccountsMainRouter: ExportPresenterDelegate {
    func createExportPassword() -> AnyPublisher<String, Error> {
        let cleanup: (Result<String, Error>) -> Future<String, Error> = { [weak self] result in
                    let future = Future<String, Error> { promise in
                        self?.navigationController.dismiss(animated: true) {
                            promise(result)
                        }
                        self?.childCoordinators.removeAll { coordinator in
                            coordinator is CreateExportPasswordCoordinator
                        }
                    }
                    return future
                }
        return showCreateExportPassword()
                .flatMap { cleanup(.success($0)) }
                .catch { cleanup(.failure($0)) }
                .eraseToAnyPublisher()
    }

    func shareExportedFile(url: URL, completion: @escaping () -> Void) {
        share(items: [url], from: navigationController) { completed in
            if completed {
                AppSettings.needsBackupWarning = false
            }
            
            completion()
            self.exportFinished()
        }
    }
    
    func exportFinished() {
        navigationController.popViewController(animated: true)
        isUserMakeBackup = true
    }
    
    
    private func showCreateExportPassword() -> AnyPublisher<String, Error> {
        let selectExportPasswordCoordinator = CreateExportPasswordCoordinator(
            navigationController: CXNavigationController(),
            dependencyProvider: ServicesProvider.defaultProvider()
        )
        self.childCoordinators.append(selectExportPasswordCoordinator)
        selectExportPasswordCoordinator.navigationController.modalPresentationStyle = .fullScreen
        selectExportPasswordCoordinator.start()
        navigationController.present(selectExportPasswordCoordinator.navigationController, animated: true)
        return selectExportPasswordCoordinator.passwordPublisher.eraseToAnyPublisher()
    }
    
    func share(
        items activityItems: [URL] = [],
        activities applicationActivities: [UIActivity] = [],
        from navController: UINavigationController,
        completion: @escaping (Bool) -> Void
    ) {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.completionWithItemsHandler = { exportActivityType, completed, _, _ in
            // exportActivityType == nil means that the user pressed the close button on the share sheet
            if completed || exportActivityType == nil {
                completion(completed)
            }
        }
        navController.present(vc, animated: true)
    }
}
