//
// Created by Concordium on 24/04/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation
import UIKit
import Combine
import SwiftUI

protocol MoreCoordinatorDelegate: IdentitiesCoordinatorDelegate {
    func logoutAccounts()
    func showRevealSeedPrase()
    func showExportWalletPrivateKey()
}

@MainActor
class MoreCoordinator: Coordinator, ShowAlert, MoreCoordinatorDelegate {
    typealias DependencyProvider = MoreFlowCoordinatorDependencyProvider & IdentitiesFlowCoordinatorDependencyProvider
    
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    private var dependencyProvider: DependencyProvider
    private var loginDependencyProvider: LoginDependencyProvider
    private var sanityChecker: SanityChecker
    private var accountsCoordinator: AccountsCoordinator?
    private let mobileWallet: MobileWalletProtocol
    
    weak var delegate: MoreCoordinatorDelegate?
    weak var parentCoordinator: MoreCoordinatorDelegate?
    private var cancellables: [AnyCancellable] = []
    
    init(navigationController: UINavigationController,
         dependencyProvider: DependencyProvider & LoginDependencyProvider & WalletAndStorageDependencyProvider,
         parentCoordinator: MoreCoordinatorDelegate
    ) {
        self.mobileWallet = dependencyProvider.mobileWallet()
        self.navigationController = navigationController
        self.dependencyProvider = dependencyProvider
        self.loginDependencyProvider = dependencyProvider
        self.sanityChecker = SanityChecker(mobileWallet: dependencyProvider.mobileWallet(),
                                           storageManager: dependencyProvider.storageManager())
        self.parentCoordinator = parentCoordinator
        sanityChecker.errorDisplayer = self
        sanityChecker.coordinator = self
    }
    
    func start() {
        showMenu()
    }
    
    func showIdentities() {
        let identitiesCoordinator = IdentitiesCoordinator(navigationController: navigationController,
                                                          dependencyProvider: dependencyProvider,
                                                          parentCoordinator: self)
        self.childCoordinators.append(identitiesCoordinator)
        identitiesCoordinator.showInitial(animated: true)
    }
    
    func showCreateNewIdentity() {
        let identitiesCoordinator = IdentitiesCoordinator(navigationController: navigationController,
                                                          dependencyProvider: dependencyProvider,
                                                          parentCoordinator: self)
        self.childCoordinators.append(identitiesCoordinator)
        identitiesCoordinator.start()
        identitiesCoordinator.showCreateNewIdentity()
    }
    
    func showMenu() {
        let vc = MoreMenuFactory.create(with: MoreMenuPresenter(dependencyProvider: dependencyProvider, delegate: self))
        vc.tabBarItem = UITabBarItem(title: "more_tab_title".localized, image: UIImage(named: "more_tab_icon"), tag: 0)
        navigationController.pushViewController(vc, animated: false)
    }
    
    // MARK: Address Book
    func showAddressBook() {
        let vc = SelectRecipientFactory.create(with: SelectRecipientPresenter(delegate: self,
                                                                              storageManager: dependencyProvider.storageManager(),
                                                                              mode: .addressBook))
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showAddRecipient() {
        let vc = AddRecipientFactory.create(with: AddRecipientPresenter(delegate: self, dependencyProvider: dependencyProvider, mode: .add))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showScanAddressQR() {
        let vc = ScanAddressQRFactory.create(with: ScanAddressQRPresenter(wallet: dependencyProvider.mobileWallet(), delegate: self))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showEditRecipient(_ recipient: RecipientDataType) {
        let vc = AddRecipientFactory.create(with: AddRecipientPresenter(delegate: self,
                                                                        dependencyProvider: dependencyProvider,
                                                                        mode: .edit(recipient: recipient)))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    //    // MARK: Import
    func showImport() {
        let initialAccountPresenter = InitialAccountInfoPresenter(delegate: self, type: .importAccount)
        let vc = InitialAccountInfoFactory.create(with: initialAccountPresenter)
        vc.title = initialAccountPresenter.type.getViewModel().title
        navigationController.pushViewController(vc, animated: true)
    }
    //
    //    // MARK: Export
    func showExport() {
        navigationController.popToRootViewController(animated: false)
        let vc = ExportFactory.create(with: ExportPresenter(dependencyProvider: dependencyProvider, requestPasswordDelegate: self, delegate: self))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showCreateExportPassword() -> AnyPublisher<String, Error> {
        let selectExportPasswordCoordinator = CreateExportPasswordCoordinator(navigationController: CXNavigationController(),
                                                                              dependencyProvider: dependencyProvider)
        self.childCoordinators.append(selectExportPasswordCoordinator)
        selectExportPasswordCoordinator.navigationController.modalPresentationStyle = .fullScreen
        selectExportPasswordCoordinator.start()
        navigationController.present(selectExportPasswordCoordinator.navigationController, animated: true)
        return selectExportPasswordCoordinator.passwordPublisher.eraseToAnyPublisher()
    }
    
    // MARK: Update password or biometrics
    func showUpdatePasscode() {
        let updatePasswordCoordinator = UpdatePasswordCoordinator(navigationController: navigationController,
                                                                  parentCoordinator: self,
                                                                  requestPasswordDelegate: self,
                                                                  dependencyProvider: loginDependencyProvider,
                                                                  walletAndStorage: dependencyProvider)
        self.childCoordinators.append(updatePasswordCoordinator)
        updatePasswordCoordinator.start()
    }
    
    // MARK: Analytics
    
    func showAnalytics() {
        let analyticsVc = UIHostingController(rootView: AnalyticsView())
        analyticsVc.title = "Analytics"
        navigationController.pushViewController(analyticsVc, animated: true)
    }
    
    
    // MARK: About
    func showAbout() {
        let vc = AboutFactory.create(with: AboutPresenter(delegate: self))
        vc.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(vc, animated: true)
    }
    
    // MARK: Notifications
    func showNotifications() {
        let notificationsVc = UIHostingController(rootView: NotificationsView())
        notificationsVc.title = "more.notifications".localized
        navigationController.pushViewController(notificationsVc, animated: true)
    }
    
    func logoutAccounts() {}
}

extension MoreCoordinator: MoreMenuPresenterDelegate {
    func showUnshieldAssetsFlow() {
        let viewModel = ShieldedAccountsViewModel(dependencyProvider: dependencyProvider as! AccountsFlowCoordinatorDependencyProvider)
        let view = ShieldedAccountsView(viewModel: viewModel)
        let viewController = SceneViewController(content: view)
        viewController.hidesBottomBarWhenPushed = true
        viewController.modalPresentationStyle = .overFullScreen
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    func showRevealSeedPrase() {
        parentCoordinator?.showRevealSeedPrase()
    }
    
    func logout() {
        requestUserPassword(keychain: dependencyProvider.keychainWrapper())
            .sink(receiveError: { _ in},
                  receiveValue: { [weak self] pass in
                guard let self = self else { return }
                do {
                    try self.dependencyProvider.storageManager().removeAllAccounts()
                    self.parentCoordinator?.logoutAccounts()
                } catch {
                    logger.error("[More Coordinator] logout error: \(error.localizedDescription)")
                }
            }).store(in: &cancellables)
    }
    
    func importSelected() {
        showImport()
    }
    func exportSelected() {
        showExport()
    }
    
    func identitiesSelected() {
        showIdentities()
    }
    
    func addressBookSelected() {
        showAddressBook()
    }
    
    func updateSelected() {
        showUpdatePasscode()
    }
    
    func recoverySelected() async throws {
        let pwHash = try await self.requestUserPassword(keychain: dependencyProvider.keychainWrapper())
        let seedValue = try dependencyProvider.keychainWrapper().getValue(for: "RecoveryPhraseSeed", securedByPassword: pwHash).get()
        
        let presenter = IdentityRecoveryStatusPresenter(
            recoveryPhrase: nil,
            recoveryPhraseService: nil,
            seed: Seed(value: seedValue),
            pwHash: pwHash,
            identitiesService: dependencyProvider.seedIdentitiesService(),
            accountsService: dependencyProvider.seedAccountsService(),
            keychain: dependencyProvider.keychainWrapper(),
            delegate: self
        )
        let vc = presenter.present(IdentityReccoveryStatusView.self)
        vc.modalPresentationStyle = .overFullScreen
        navigationController.present(vc, animated: true)
    }
    
    func analyticsSelected() {
        showAnalytics()
    }
    
    func aboutSelected() {
        showAbout()
    }
    
    func notificationsSelected() {
        showNotifications()
    }
    
    func showExportWalletPrivateKey() {
        parentCoordinator?.showExportWalletPrivateKey()
    }
}

extension MoreCoordinator: SelectRecipientPresenterDelegate {
    func didSelect(recipient: RecipientDataType) {
        showEditRecipient(recipient)
    }
    
    func createRecipient() {
        showAddRecipient()
    }
    
    func selectRecipientDidSelectQR() {
        DispatchQueue.main.async {
            self.showScanAddressQR()
        }
    }
}

extension MoreCoordinator: AddRecipientPresenterDelegate {
    
    func addRecipientDidSelectSave(recipient: RecipientDataType) {
        navigationController.popViewController(animated: true)
    }
    
    func addRecipientDidSelectQR() {
        showScanAddressQR()
    }
}

extension MoreCoordinator: ScanAddressQRPresenterDelegate, AddRecipientCoordinatorHelper {
    func scanAddressQr(didScan output: QRScannerOutput) {
        switch output {
            case .address(let string):
                scanAddressQr(didScanAddress: string)
            case .airdrop, .connectURL, .walletConnectV2: break
        }
    }
    
    func scanAddressQr(didScanAddress address: String) {
        let addRecipientViewController = getAddRecipientViewController(dependencyProvider: dependencyProvider)
        self.navigationController.popToViewController(addRecipientViewController, animated: true)
        addRecipientViewController.presenter.setAccountAddress(address)
    }
}

extension MoreCoordinator: InitialAccountInfoPresenterDelegate {
    func userTappedClose() {
        navigationController.popToRootViewController(animated: true)
    }
    
    func userTappedOK(withType type: InitialAccountInfoType) {
        switch type {
            case .importAccount:
                navigationController.popViewController(animated: true)
            default: break // no action - we shouldn't reach it in this flow
        }
    }
}

extension MoreCoordinator: UpdatePasswordCoordinatorDelegate {
    func passcodeChanged() {
        navigationController.popViewController(animated: false)
        childCoordinators.removeAll(where: { $0 is UpdatePasswordCoordinator })
        let options = AlertOptions(title: "",
                                   message: "more.update.successfully".localized,
                                   actions: [AlertAction(name: "ok".localized,
                                                         completion: {},
                                                         style: .default)] )
        showAlert(with: options)
    }
}

extension MoreCoordinator: ExportPresenterDelegate {
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
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
        vc.completionWithItemsHandler = { exportActivityType, completed, _, _ in
            // exportActivityType == nil means that the user pressed the close button on the share sheet
            
            if completed {
                AppSettings.needsBackupWarning = false
            }
            
            if completed || exportActivityType == nil {
                completion()
                self.exportFinished()
            }
        }
        self.navigationController.present(vc, animated: true)
    }
    
    func exportFinished() {
        navigationController.popViewController(animated: true)
    }
}

extension MoreCoordinator: AboutPresenterDelegate {}

extension MoreCoordinator: IdentitiesCoordinatorDelegate {
    
    func noIdentitiesFound() {
        self.delegate?.noIdentitiesFound()
    }
    
    func finishedDisplayingIdentities() {
        self.childCoordinators.removeAll { coordinator in
            coordinator is CreateExportPasswordCoordinator
        }
    }
}

extension MoreCoordinator: IdentityRecoveryStatusPresenterDelegate {
    func identityRecoveryCompleted() {
        navigationController.dismiss(animated: true)
    }
    
    func reenterRecoveryPhrase() {
        print("Reenter recovery phrase.")
    }
}

extension MoreCoordinator: AppSettingsDelegate {
    func checkForAppSettings() {
    }
}

extension MoreCoordinator: AccountsPresenterDelegate {
    func scanQR() {}
    func noValidIdentitiesAvailable() { }
    func tryAgainIdentity() { }
    func didSelectMakeBackup() { }
    func didSelectPendingIdentity(identity: IdentityDataType) { }
    
    func createNewIdentity() {
        accountsCoordinator?.showCreateNewIdentity()
    }
    
    func createNewAccount() {
        accountsCoordinator?.showCreateNewAccount()
    }
    
    func userPerformed(action: AccountCardAction, on account: AccountDataType) {
        accountsCoordinator?.userPerformed(action: action, on: account)
    }
    
    func newTermsAvailable() {
        accountsCoordinator?.showNewTerms()
    }
    
    func showSettings() {
        let moreCoordinator = MoreCoordinator(navigationController: self.navigationController,
                                              dependencyProvider: ServicesProvider.defaultProvider(),
                                              parentCoordinator: self)
        moreCoordinator.start()
    }
}


extension MoreCoordinator: RequestPasswordDelegate {
    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
        DummyRequestPasswordDelegate().requestUserPassword(keychain: keychain)
    }
}
