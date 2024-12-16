//
//  AccountsMainRouter.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 28.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import UIKit
import WalletConnectPairing
import Web3Wallet
import Combine
import SwiftUI

extension AccountsMainRouter: AccountsMainViewDelegate {}

final class AccountsMainRouter: ObservableObject {
    let navigationController: UINavigationController = CXNavigationController()
    
    private let dependencyProvider: ServicesProvider
    private let walletConnectService: WalletConnectService
    private let onAccountsUpdate = PassthroughSubject<Void, Never>()
    weak var configureAccountAlertDelegate: ConfigureAccountAlertDelegate?

    @AppStorage("isUserMakeBackup") private var isUserMakeBackup = false
    @AppStorage("isShouldShowSunsetShieldingView") private var isShouldShowSunsetShieldingView = true

    /// Legacy codebase support
    var childCoordinators = [Coordinator]()
    let updateTimer = UpdateTimer()

    init(dependencyProvider: ServicesProvider, walletConnectService: WalletConnectService) {
        self.dependencyProvider = dependencyProvider
        self.walletConnectService = walletConnectService
        self.walletConnectService.delegate = self
    }
    
    func rootScene() -> UINavigationController {        
        let viewModel: AccountsMainViewModel = .init(dependencyProvider: dependencyProvider, onReload: onAccountsUpdate.eraseToAnyPublisher(), walletConnectService: walletConnectService)
        let view = AccountsMainView(viewModel: viewModel, keychain: dependencyProvider.keychainWrapper(), identitiesService: dependencyProvider.seedIdentitiesService(), router: self)
            .environmentObject(updateTimer)
        let viewController = SceneViewController(content: view)
        viewController.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "tab_item_home"), tag: 0)
        viewController.tabBarItem.selectedImage = UIImage(named: "tab_item_home_selected")?.withRenderingMode(.alwaysOriginal)
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }
    
    @MainActor func showUnshieldAssetsFlow() {
        let viewModel = ShieldedAccountsViewModel(dependencyProvider: dependencyProvider)
        let view = ShieldedAccountsView(viewModel: viewModel)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        viewController.modalPresentationStyle = .overFullScreen
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    @MainActor func showAccountDetail(_ account: AccountDataType) {
        let router = AccountDetailRouter(account: account, navigationController: navigationController, dependencyProvider: dependencyProvider)
        router.accountMainViewDelegate = self
        let viewModel = AccountDetailViewModel(
            router: router,
            account: account,
            storageManager: dependencyProvider.storageManager(),
            dependencyProvider: dependencyProvider
        )
        let view = AccountDetailView(viewModel: viewModel)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showSendFundsFlow(_ account: AccountDataType) {
        //TODO: - add tip here why this (`SendToken`) button isnt tappable
        guard account.isReadOnly == false else { return }
        guard account.forecastAtDisposalBalance > 0 else { return }
        let router = TransferTokenRouter(root: navigationController, account: account, dependencyProvider: dependencyProvider)
        router.showSendTokenFlow(tokenType: .ccd)
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
}

extension AccountsMainRouter {
    func showScanQRFlow() {
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), delegate: self))
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
    
    func showSaveSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void) {
        let view =  CreateSeedPhraseView(
            viewModel: .init(pwHash: pwHash, identitiesService: identitiesService),
            onConfirmed: { phrase in
                DispatchQueue.main.async { [weak self] in
                    self?.navigationController.dismiss(animated: true, completion: nil)
                }
                completion(phrase)
            })
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

extension AccountsMainRouter: ScanAddressQRPresenterDelegate {
    func scanAddressQr(didScan output: QRScannerOutput) {
        navigationController.popViewController(animated: true)
        switch output {
            case .address: break
            case .airdrop(let string):
                scanAddressQr(didScanAddress: string)
            case .connectURL(let string):
                scanAddressQr(didScanAddress: string)
            case .walletConnectV2(let address):
                self.showWalletConnectFlow(address)
        }
    }
    
    /*
     "https://cwb.stage.spaceseven.cloud/condition/465063159330244033/XPt1SBqta9hULKWvq8EkhFc2yjSlKgU42w594WR$8nUPgN1iMZ4JFZRJmR9$Vh4@MEcZ94T@oEFJPcClIjeMfL2j@opc@bzZfOZ6hGqMhG25Ik0w4juitXYzkAl2rOPy"
     */
    
    func scanAddressQr(didScanAddress address: String) {
        
        let url = URL(string: address)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                return
            }
            guard let data = data else {return}
            
            do {
                let dataResponse = try JSONDecoder().decode(QRDataResponse.self, from: data)
                let t = try JSONSerialization.jsonObject(with: data, options: [])
                
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
            } catch let jsonErr {
                print(jsonErr)
            }
        }
        task.resume()
    }
}

extension AccountsMainRouter {
    public func handlWCDeeplinkConnect(_ url: URL) {
        Task {
            await self.walletConnectService.pair(url.absoluteString)
        }
    }
    
    private func showWalletConnectFlow(_ address: String) {
        Task {
            await self.walletConnectService.pair(address)
        }
    }
}

extension AccountsMainRouter: WalletConnectServiceProtocol {
    func showSessionRequest(with request: WalletConnectSign.Request) {
        let viewController = ClearSceneViewController(
            content: SessionRequestView(
                viewModel: .init(
                    sessionRequest: request,
                    transactionsService: self.dependencyProvider.transactionsService(),
                    storageManager: self.dependencyProvider.storageManager(), 
                    mobileWallet: self.dependencyProvider.mobileWallet()
                )
            )
        )
        self.navigationController.present(viewController, animated: true)
    }
    
    func showSessionProposal(with proposal: Session.Proposal, context: VerifyContext?) {
        let viewController = ClearSceneViewController(
            content: SessionProposalView(
                viewModel: .init(
                    sessionProposal: proposal,
                    wallet: self.dependencyProvider.mobileWallet(),
                    storageManager: self.dependencyProvider.storageManager())
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
