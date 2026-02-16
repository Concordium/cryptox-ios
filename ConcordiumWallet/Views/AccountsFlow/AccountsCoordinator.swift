//
//  AccountsCoordinator.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Combine
import Foundation
import UIKit

protocol AccountsCoordinatorDelegate: AnyObject {
    func createNewIdentity()
    func createNewAccount()
    func noIdentitiesFound()
    func showIdentities()
    func showScanAddressQR()
}

@MainActor
class AccountsCoordinator: Coordinator {
    typealias DependencyProvider = AccountsFlowCoordinatorDependencyProvider &
    StakeCoordinatorDependencyProvider &
    IdentitiesFlowCoordinatorDependencyProvider
    
    private var publishers = [AnyCancellable]()

    
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    weak var delegate: AccountsCoordinatorDelegate?
    weak var accountsPresenterDelegate: AccountsPresenterDelegate?

    private weak var appSettingsDelegate: AppSettingsDelegate?
    private var dependencyProvider: ServicesProvider
    private let walletConnectService: WalletConnectService

    
    deinit { print("[deallocated] -- \(String(describing: self))") }
    init(
        navigationController: UINavigationController,
        dependencyProvider: ServicesProvider,
        appSettingsDelegate: AppSettingsDelegate?,
        walletConnectService: WalletConnectService
    ) {
        self.navigationController = navigationController
        self.dependencyProvider = dependencyProvider
        self.appSettingsDelegate = appSettingsDelegate
        self.walletConnectService = walletConnectService

        self.accountsPresenterDelegate = self
        self.walletConnectService.delegate = self
    }

    func start() { }
    
    func showCreateNewAccount(withDefaultValuesFrom account: AccountDataType? = nil) {
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
                                                                    dependencyProvider: dependencyProvider, parentCoordinator: self)
            childCoordinators.append(createAccountCoordinator)
            createAccountCoordinator.start(withDefaultValuesFrom: account)
            navigationController.present(createAccountCoordinator.navigationController, animated: true, completion: nil)
        }
    }
    
    func showCreateNewIdentity() {
        if dependencyProvider.mobileWallet().isLegacyAccount() {
            let createIdentityCoordinator = CreateIdentityCoordinator(navigationController: CXNavigationController(),
                    dependencyProvider: dependencyProvider, parentCoordinator: self)
            childCoordinators.append(createIdentityCoordinator)
            createIdentityCoordinator.start()
            navigationController.present(createIdentityCoordinator.navigationController, animated: true, completion: nil)
        } else {
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
    }
    
    func show(account: AccountDataType, entryPoint: AccountDetailsFlowEntryPoint) {
        let accountDetailsCoordinator = AccountDetailsCoordinator(navigationController: navigationController,
                                                                  dependencyProvider: dependencyProvider,
                                                                  parentCoordinator: self,
                                                                  account: account)
        childCoordinators.append(accountDetailsCoordinator)
        accountDetailsCoordinator.start(entryPoint: entryPoint)
    }

    func showExport() {
        let vc = ExportFactory.create(with: ExportPresenter(
            dependencyProvider: ServicesProvider.defaultProvider(),
            requestPasswordDelegate: self,
            delegate: self
        ))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
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
}

extension AccountsCoordinator: AccountsPresenterDelegate {
    func scanQR() {
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), delegate: self))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showSettings() {
    }
    
    func didSelectMakeBackup() {
        showExport()
    }
    
    func didSelectPendingIdentity(identity: IdentityDataType) {
        delegate?.showIdentities()
    }
    
    func createNewAccount() {
        delegate?.createNewAccount()
    }

    func createNewIdentity() {
        delegate?.createNewIdentity()
    }
    
    func userPerformed(action: AccountCardAction, on account: AccountDataType) {
        let entryPoint: AccountDetailsFlowEntryPoint!
        switch action {
        case .tap, .more:
            entryPoint = .settings
        case .receive:
            entryPoint = .receive
        }
        show(account: account, entryPoint: entryPoint)
    }
    
    func noValidIdentitiesAvailable() {
        self.delegate?.noIdentitiesFound()
    }

    func tryAgainIdentity() {
        self.delegate?.createNewIdentity()
    }
}

extension AccountsCoordinator: CreateNewAccountDelegate {
    func createNewAccountFinished() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateAccountCoordinator })
    }
    
    func createNewAccountCancelled() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateAccountCoordinator })
    }
}

extension AccountsCoordinator: AccountDetailsDelegate {
    func accountDetailsClosed() {
        navigationController.dismiss(animated: true, completion: nil)
        if let lastOccurenceIndex = childCoordinators.lastIndex(where: { $0 is AccountDetailsCoordinator }) {
            childCoordinators.remove(at: lastOccurenceIndex)
        }
    }
    
    func retryCreateAccount(failedAccount: AccountDataType) {
        navigationController.popViewController(animated: true)
        showCreateNewAccount(withDefaultValuesFrom: failedAccount)
    }

    func accountRemoved() {
        navigationController.popViewController(animated: true)
    }
}

extension AccountsCoordinator: RequestPasswordDelegate { }

extension AccountsCoordinator: ExportPresenterDelegate {
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
    }
}

extension AccountsCoordinator: SeedIdentitiesCoordinatorDelegate {
    func seedIdentityCoordinatorWasFinished(for identity: IdentityDataType) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is SeedIdentitiesCoordinator })
        
        NotificationCenter.default.post(name: Notification.Name("seedAccountCoordinatorWasFinishedNotification"), object: nil)
    }
    
    func seedIdentityCoordinatorDidFail(with error: IdentityRejectionError) {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is SeedIdentitiesCoordinator })
    }
}


extension AccountsCoordinator: ScanAddressQRPresenterDelegate {
    func showScanAddressQR() {
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), delegate: self))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    func scanAddressQr(didScan output: QRScannerOutput) {
        switch output {
            case .address:
                navigationController.popViewController(animated: true)
            case .airdrop(let string):
                navigationController.popViewController(animated: true)
                scanAddressQr(didScanAddress: string)
            case .connectURL(let string):
                navigationController.popViewController(animated: true)
                scanAddressQr(didScanAddress: string)
            case .walletConnectV2(let address):
                let scannerVC = navigationController.topViewController as? ScanAddressQRViewController
                self.showWalletConnectFlow(address, scannerViewController: scannerVC)
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
            
            if let error = error { return }
            guard let data = data else { return }
            
            
            do{
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
            } catch { }
        }
        task.resume()
    }
}

//import WalletConnectPairing
//import WalletConnectKMS
import SwiftUI
import ReownWalletKit

extension AccountsCoordinator {
    func showWalletConnectFlow(_ address: String, scannerViewController: ScanAddressQRViewController? = nil) {
        Task { @MainActor in
            let result = await self.walletConnectService.pair(address)
            switch result {
            case .success:
                if let scannerViewController = scannerViewController,
                   scannerViewController.isViewLoaded && scannerViewController.view.window != nil {
                    navigationController.popViewController(animated: true)
                }
            case .failure(let error):
                showWalletConnectError(error, scannerViewController: scannerViewController)
            }
        }
    }
    
    private func showWalletConnectError(_ error: Error, scannerViewController: ScanAddressQRViewController?) {
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
        
        DispatchQueue.main.async { [weak self, weak scannerViewController] in
            guard let self = self else { return }
            
            let alert = UIAlertController(
                title: "Connection Error",
                message: errorMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                if let scannerViewController = scannerViewController {
                    scannerViewController.dismissScanner()
                } else {
                    self?.navigationController.dismiss(animated: true)
                }
            })
            
            if let topViewController = self.navigationController.topViewController,
               !topViewController.isBeingPresented && !topViewController.isBeingDismissed {
                self.navigationController.present(alert, animated: true)
            }
        }
    }
}

extension AccountsCoordinator: WalletConnectServiceProtocol {
    func showSessionRequest(with request: WalletConnectSign.Request, redirectURL: String?) {
        let viewController = ClearSceneViewController(
            content: SessionRequestView(
                viewModel: .init(
                    sessionRequest: request,
                    transactionsService: self.dependencyProvider.transactionsService(),
                    storageManager: self.dependencyProvider.storageManager(),
                    mobileWallet: self.dependencyProvider.mobileWallet(),
                    concordiumClient: try! ConcordiumClient(
                        networkManager: self.dependencyProvider.networkManager(),
                        storageManager: self.dependencyProvider.storageManager()),
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
        self.navigationController.present(viewController, animated: true)
    }
}


extension AccountsCoordinator: CreateNewIdentityDelegate {
    func createNewIdentityFinished() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateIdentityCoordinator })
    }

    func createNewIdentityCancelled() {
        navigationController.dismiss(animated: true)
        childCoordinators.removeAll(where: { $0 is CreateIdentityCoordinator })
    }
}
