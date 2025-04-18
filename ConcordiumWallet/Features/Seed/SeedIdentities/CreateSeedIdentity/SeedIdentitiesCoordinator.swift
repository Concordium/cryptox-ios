//
//  SeedIdentitiesCoordinator.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 04/08/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

protocol SeedIdentitiesCoordinatorDelegate: AnyObject {
    func seedIdentityCoordinatorWasFinished(for identity: IdentityDataType)
    func seedIdentityCoordinatorDidFail(with error: IdentityRejectionError)
}

protocol SubmittedSeedAccountPresenterDelegate: AnyObject {
    func accountHasBeenFinished(for identity: IdentityDataType)
}

@MainActor
class SeedIdentitiesCoordinator: Coordinator, ShowAlert {
    enum Action {
        case createInitialIdentity
        case createAccount
        case createIdentity
    }
    
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    private let action: Action
    private let dependencyProvider: IdentitiesFlowCoordinatorDependencyProvider
    private let identititesService: SeedIdentitiesService
    private weak var delegate: SeedIdentitiesCoordinatorDelegate?
    private var creationFailedUIMode: CreationFailedUIMode = .identity
    private var accountsCoordinator: AccountsCoordinator?
    
    init(
        navigationController: UINavigationController,
        action: Action,
        dependencyProvider: IdentitiesFlowCoordinatorDependencyProvider,
        delegate: SeedIdentitiesCoordinatorDelegate
    ) {
        self.navigationController = navigationController
        self.action = action
        self.dependencyProvider = dependencyProvider
        self.identititesService = dependencyProvider.seedIdentitiesService()
        self.delegate = delegate
    }
    
    func start() {
        switch action {
        case .createInitialIdentity:
            if let pendingIdentity = identititesService.pendingIdentity {
                showSubmitAccount(for: pendingIdentity)
            } else {
                showOnboarding()
            }
        case .createAccount:
            showIdentitySelection()
        case .createIdentity:
            showIdentityProviders(isNewIdentityAfterSettingUpTheWallet: true)
        }
        
    }
    
    private func showOnboarding() {
        let presenter = SeedIdentityOnboardingPresenter(delegate: self)
        
        navigationController.setViewControllers([presenter.present(SeedIdentityOnboardingView.self)], animated: true)
    }
    
    private func showIdentityProviders(enablePop: Bool = true, isNewIdentityAfterSettingUpTheWallet: Bool = false) {
        let identityView = IdentityProviderListView(viewModel: .init(identitiesService: identititesService,
                                                                     delegate: self,
                                                                     isNewIdentityAfterSettingUpTheWallet: isNewIdentityAfterSettingUpTheWallet))
        
        let vc = SceneViewController(content: identityView)
        if enablePop {
            navigationController.pushViewController(vc, animated: true)
        } else {
            navigationController.present(vc, animated: true)
        }
    }
    
    private func showCreateIdentity(request: IDPIdentityRequest, isNewIdentityAfterSettingUpTheWallet: Bool = false) {
        let presenter = CreateSeedIdentityPresenter(
            request: request,
            identitiesService: identititesService,
            delegate: self,
            isNewIdentityAfterSettingUpTheWallet: isNewIdentityAfterSettingUpTheWallet
        )
        
        let viewController = presenter.present(CreateSeedIdentityView.self)
        viewController.modalPresentationStyle = .fullScreen
        navigationController.present(viewController, animated: true)
    }
    
    private func showIdentityStatus(identity: IdentityDataType, isNewIdentityAfterSettingUpTheWallet: Bool = false) {
        navigationController.dismiss(animated: true)
        _ = SeedIdentityStatusService(
            identity: identity,
            identitiesService: identititesService,
            isNewIdentityAfterSettingUpTheWallet: isNewIdentityAfterSettingUpTheWallet,
            delegate: self
        )
    }
    
    private func showSubmitAccount(for identity: IdentityDataType, isNewAccountAfterSettingUpTheWallet: Bool = false) {
        let presenter = SubmitSeedAccountPresenter(
            identity: identity,
            identitiesService: identititesService,
            accountsService: dependencyProvider.seedAccountsService(),
            delegate: self,
            isNewAccountAfterSettingUpTheWallet: isNewAccountAfterSettingUpTheWallet
        )
        
        navigationController.setViewControllers([presenter.present(SubmitSeedAccountView.self)], animated: true)
    }
    
    private func showIdentitySelection() {
        let presenter = SelectIdentityPresenter(
            identities: identititesService.confirmedIdentities,
            delegate: self
        )
        
        navigationController.pushViewController(presenter.present(SelectIdentityView.self), animated: true)
    }
    
    func recoverySelected() async throws {
        let pwHash = try await self.requestUserPassword(keychain: KeychainWrapper())
        let seedValue = try KeychainWrapper().getValue(for: "RecoveryPhraseSeed", securedByPassword: pwHash).get()
        
        let presenter = IdentityRecoveryStatusPresenter(
            recoveryPhrase: nil,
            recoveryPhraseService: nil,
            seed: Seed(value: seedValue),
            pwHash: pwHash,
            identitiesService: dependencyProvider.seedIdentitiesService(),
            accountsService: dependencyProvider.seedAccountsService(),
            keychain: KeychainWrapper(),
            delegate: self
        )
        
        replaceTopController(with: presenter.present(IdentityReccoveryStatusView.self))
    }
    
    private func replaceTopController(with controller: UIViewController) {
        let viewControllers = navigationController.viewControllers.filter { $0.isPresenting(page: RecoveryPhraseGettingStartedView.self) }
        navigationController.setViewControllers(viewControllers + [controller], animated: true)
    }
}

extension SeedIdentitiesCoordinator: SeedIdentityOnboardingPresenterDelegate {
    func onboardingDidFinish() {
        showIdentityProviders()
    }
}

extension SeedIdentitiesCoordinator: SelectIdentityProviderPresenterDelegate {
    func showIdentityProviderInfo(url: URL) {
        navigationController.present(
            SFSafariViewController(url: url),
            animated: true
        )
    }
    
    func createIdentityRequestCreated(_ request: IDPIdentityRequest, isNewIdentityAfterSettingUpTheWallet: Bool) {
        showCreateIdentity(request: request, isNewIdentityAfterSettingUpTheWallet: isNewIdentityAfterSettingUpTheWallet)
    }
}

extension SeedIdentitiesCoordinator: CreateSeedIdentityPresenterDelegate {
    func pendingIdentityCreated(_ identity: IdentityDataType, isNewIdentityAfterSettingUpTheWallet: Bool) {
        navigationController.dismiss(animated: true) {
            self.showIdentityStatus(identity: identity, isNewIdentityAfterSettingUpTheWallet: isNewIdentityAfterSettingUpTheWallet)
        }
    }
    
    func createIdentityView(failedToLoad error: Error) {
        navigationController.dismiss(animated: true) {
            self.creationFailedUIMode = .identity
            let vc = CreationFailedFactory.create(
                with: CreationFailedPresenter(
                    serverError: error,
                    delegate: self,
                    mode: .identity
                )
            )
            self.showModally(vc, from: self.navigationController)
        }
    }
    
    func cancelCreateIdentity() {
        navigationController.dismiss(animated: true)
    }
}

extension SeedIdentitiesCoordinator: CreationFailedPresenterDelegate {
    func finish() {
        if creationFailedUIMode == .identity {
            navigationController.dismiss(animated: true)
            childCoordinators.removeAll()
        } else if creationFailedUIMode == .account {
            Task {
                do {
                    navigationController.dismiss(animated: false)
                    childCoordinators.removeAll(where: { $0 is SeedIdentitiesCoordinator })
                    try await recoverySelected()
                } catch {
                }
            }
        }
    }
}

extension SeedIdentitiesCoordinator: SeedIdentityStatusPresenterDelegate {
    func seedIdentityStatusDidFinish(with identity: IdentityDataType) {
        showSubmitAccount(for: identity)
    }
    
    func seedNewIdentityStatusDidFinish(with identity: IdentityDataType) {
        delegate?.seedIdentityCoordinatorWasFinished(for: identity)
    }
    
    func makeNewIdentityRequestAfterSettingUpWallet() {
        showIdentityProviders(enablePop: false, isNewIdentityAfterSettingUpTheWallet: true)
    }
    
    func makeNewAccount(with identity: IdentityDataType) {
        showSubmitAccount(for: identity, isNewAccountAfterSettingUpTheWallet: true)
    }
    
    func seedIdentityStatusDidFail(with error: IdentityRejectionError) {
        delegate?.seedIdentityCoordinatorDidFail(with: error)
    }
}

extension SeedIdentitiesCoordinator: SubmitSeedAccountPresenterDelegate {
    func accountHasBeenSubmitted(_ account: AccountDataType, isNewAccountAfterSettingUpTheWallet: Bool, forIdentity identity: IdentityDataType) {
            delegate?.seedIdentityCoordinatorWasFinished(for: identity)
    }
    
    func makeNewIdentityRequest() {
        showIdentityProviders(enablePop: false)
    }
    
    func showAccountFailed(error: Error) {
        creationFailedUIMode = .account
        let vc = CreationFailedFactory.create(with: CreationFailedPresenter(serverError: error, delegate: self, mode: .account))
        showModally(vc, from: navigationController)
    }
    
    func cancelAccountCreation() {
        navigationController.dismiss(animated: true)
    }
}

extension SeedIdentitiesCoordinator: SelectIdentityPresenterDelegate {
    func selectIdentityPresenter(didSelectIdentity identity: IdentityDataType) {
        showSubmitAccount(for: identity, isNewAccountAfterSettingUpTheWallet: true)
    }
}

extension SeedIdentitiesCoordinator: SubmittedSeedAccountPresenterDelegate {
    func accountHasBeenFinished(for identity: IdentityDataType) {
        delegate?.seedIdentityCoordinatorWasFinished(for: identity)
    }
}

extension SeedIdentitiesCoordinator: IdentityRecoveryStatusPresenterDelegate {
    func identityRecoveryCompleted() {
        childCoordinators.removeAll { $0 is RecoveryPhraseCoordinator }
        navigationController.dismiss(animated: true)
    }
    
    func reenterRecoveryPhrase() {
        print("Reenter recovery phrase.")
    }
}

extension SeedIdentitiesCoordinator: AppSettingsDelegate {
    func checkForAppSettings() {
    }
}

extension SeedIdentitiesCoordinator: AccountsPresenterDelegate {
    func scanQR() { }
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

    func showSettings() {
        let moreCoordinator = MoreCoordinator(navigationController: self.navigationController,
                                              dependencyProvider: ServicesProvider.defaultProvider(),
                                              parentCoordinator: self)
        moreCoordinator.start()
    }
}

extension SeedIdentitiesCoordinator: IdentitiesCoordinatorDelegate, MoreCoordinatorDelegate {
    func showExportWalletPrivateKey() {}
    func showRevealSeedPrase() {}
    func logoutAccounts() {}
    func finishedDisplayingIdentities() {}
    func noIdentitiesFound() {}
}
