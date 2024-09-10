//
//  MoreMenuPresenter.swift
//  ConcordiumWallet
//
//  Created by Concordium on 24/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation

// MARK: View
protocol MoreMenuViewProtocol: ShowAlert {

}

// MARK: -
// MARK: Delegate
protocol MoreMenuPresenterDelegate: AnyObject {
    func identitiesSelected()
    func addressBookSelected()
    func updateSelected()
    func recoverySelected() async throws
    func analyticsSelected()
    func aboutSelected()
    func exportSelected()
    func importSelected()
    func logout()
    func showRevealSeedPrase()
    func showUnshieldAssetsFlow()
    func notificationsSelected()
}

// MARK: -
// MARK: Presenter
protocol MoreMenuPresenterProtocol: AnyObject {
	var view: MoreMenuViewProtocol? { get set }
    func viewDidLoad()
    func userSelectedIdentities()
    func userSelectedAddressBook()
    func userSelectedUpdate()
    func userSelectedRecovery() async
    func userSelectedAnalytics()
    func userSelectedAbout()
    func userSelectedNotifications()
    
    func userSelectedExport()
    func userSelectedImport()
    func isLegacyAccount() -> Bool
    func logout()
    func showRevealSeedPrase()
    
    func hasSavedSeedPhrase() -> Bool
    func showUnshieldAssetsFlow()
}

class MoreMenuPresenter {
    weak var view: MoreMenuViewProtocol?
    weak var delegate: MoreMenuPresenterDelegate?

    private let dependencyProvider: MoreFlowCoordinatorDependencyProvider
    
    init(
        dependencyProvider: MoreFlowCoordinatorDependencyProvider,
        delegate: MoreMenuPresenterDelegate? = nil
    ) {
        self.delegate = delegate
        self.dependencyProvider = dependencyProvider
    }

    func viewDidLoad() {
    }
    
    func isLegacyAccount() -> Bool {
        dependencyProvider.mobileWallet().isLegacyAccount()
    }
}

extension MoreMenuPresenter: MoreMenuPresenterProtocol {
    func showUnshieldAssetsFlow() {
        delegate?.showUnshieldAssetsFlow()
    }
    
    func hasSavedSeedPhrase() -> Bool {
        dependencyProvider.seedIdentitiesService().mobileWallet.isMnemonicPhraseSaved
    }
    
    func showRevealSeedPrase() {
        delegate?.showRevealSeedPrase()
    }
    
    func userSelectedIdentities() {
        delegate?.identitiesSelected()
    }
    
    func userSelectedAddressBook() {
        delegate?.addressBookSelected()
    }

    func userSelectedUpdate() {
        delegate?.updateSelected()
    }
    
    func userSelectedRecovery() async {
        do {
            try await delegate?.recoverySelected()
        } catch {
            print(error)
        }
    }

    func userSelectedAnalytics() {
        delegate?.analyticsSelected()
    }
    
    func userSelectedAbout() {
        delegate?.aboutSelected()
    }
    
    func userSelectedExport() {
        delegate?.exportSelected()
    }
    
    func userSelectedImport() {
        delegate?.importSelected()
    }
    
    func userSelectedNotifications() {
        delegate?.notificationsSelected()
    }
    
    func logout() {
        view?.showAlert(
            with: AlertOptions(
                title: "You're removing wallet",
                message: "This will remove your wallet from this device along with your recovery phrase or backup file.",
                actions: [
                    AlertAction(name: "Cancel", completion: nil, style: .default),
                    AlertAction(name: "Continue", completion: { [weak self] in self?.delegate?.logout() }, style: .destructive),
                ]))
    }
}
