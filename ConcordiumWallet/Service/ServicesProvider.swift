//
// Created by Concordium on 26/02/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation

protocol StakeCoordinatorDependencyProvider: WalletAndStorageDependencyProvider {
    func transactionsService() -> TransactionsServiceProtocol
    func stakeService() -> StakeServiceProtocol
    func accountsService() -> AccountsServiceProtocol
    func exportService() -> ExportService
}

protocol WalletAndStorageDependencyProvider {
    func mobileWallet() -> MobileWalletProtocol
    func storageManager() -> StorageManagerProtocol
}

protocol AccountsFlowCoordinatorDependencyProvider: WalletAndStorageDependencyProvider {
    func transactionsService() -> TransactionsServiceProtocol
    func accountsService() -> AccountsServiceProtocol
    func identitiesService() -> IdentitiesService
    func networkManager() -> NetworkManagerProtocol
    func keychainWrapper() -> KeychainWrapperProtocol
}

protocol IdentitiesFlowCoordinatorDependencyProvider: WalletAndStorageDependencyProvider {
    func identitiesService() -> IdentitiesService
    func seedIdentitiesService() -> SeedIdentitiesService
    func seedAccountsService() -> SeedAccountsService
}

protocol MoreFlowCoordinatorDependencyProvider: WalletAndStorageDependencyProvider {
    func exportService() -> ExportService
    func keychainWrapper() -> KeychainWrapperProtocol
    func seedIdentitiesService() -> SeedIdentitiesService
}

protocol LoginDependencyProvider: WalletAndStorageDependencyProvider {
    func keychainWrapper() -> KeychainWrapperProtocol
    func appSettingsService() -> AppSettingsService
    func recoveryPhraseService() -> RecoveryPhraseService
    func seedMobileWallet() -> SeedMobileWalletProtocol
    func seedIdentitiesService() -> SeedIdentitiesService
    func seedAccountsService() -> SeedAccountsService
}

protocol NFTFlowCoordinatorDependencyProvider: WalletAndStorageDependencyProvider {
    func nftService() -> NFTService
}

protocol ImportDependencyProvider {
    func importService() -> ImportService
    func keychainWrapper() -> KeychainWrapperProtocol
}

class ServicesProvider {
    private let _mobileWallet: MobileWalletProtocol
    private let _networkManager: NetworkManagerProtocol
    private let _storageManager: StorageManagerProtocol
    private let _keychainWrapper: KeychainWrapper
    private let _seedMobileWallet: SeedMobileWalletProtocol

    init(mobileWallet: MobileWalletProtocol,
         networkManager: NetworkManagerProtocol,
         seedMobileWallet: SeedMobileWalletProtocol,
         storageManager: StorageManagerProtocol,
         keychainWrapper: KeychainWrapper) {
        self._mobileWallet = mobileWallet
        self._seedMobileWallet = seedMobileWallet
        self._networkManager = networkManager
        self._storageManager = storageManager
        self._keychainWrapper = keychainWrapper
    }
}

extension ServicesProvider: WalletAndStorageDependencyProvider {
    func mobileWallet() -> MobileWalletProtocol {
        _mobileWallet
    }

    func storageManager() -> StorageManagerProtocol {
        _storageManager
    }
}

extension ServicesProvider: IdentitiesFlowCoordinatorDependencyProvider {
    func identitiesService() -> IdentitiesService {
        IdentitiesService(networkManager: _networkManager, storageManager: _storageManager, mobileWallet: _mobileWallet)
    }
    
    func seedIdentitiesService() -> SeedIdentitiesService {
        SeedIdentitiesService(
            networkManager: _networkManager,
            storageManager: _storageManager,
            mobileWallet: _seedMobileWallet
        )
    }
    
    func seedAccountsService() -> SeedAccountsService {
        SeedAccountsService(
            mobileWallet: _seedMobileWallet,
            networkManager: _networkManager,
            storageManager: _storageManager,
            keychainWrapper: _keychainWrapper
        )
    }
}

extension ServicesProvider: AccountsFlowCoordinatorDependencyProvider {
    func accountsService() -> AccountsServiceProtocol {
        AccountsService(networkManager: _networkManager, mobileWallet: _mobileWallet, storageManager: _storageManager, keychain: keychainWrapper())
    }

    func transactionsService() -> TransactionsServiceProtocol {
        TransactionsService(networkManager: _networkManager, mobileWallet: _mobileWallet, storageManager: _storageManager)
    }
    
    func networkManager() -> NetworkManagerProtocol {
        _networkManager
    }
}

extension ServicesProvider: MoreFlowCoordinatorDependencyProvider {
    func exportService() -> ExportService {
        ExportService(storageManager: _storageManager)
    }
}

extension ServicesProvider: ImportDependencyProvider {
    func importService() -> ImportService {
        ImportService(storageManager: _storageManager, accountsService: accountsService(), mobileWallet: mobileWallet())
    }
}


extension ServicesProvider: NFTFlowCoordinatorDependencyProvider {
    func nftService() -> NFTService {
        NFTService(mobileWallet: _mobileWallet, networkManager: _networkManager, storageManager: _storageManager)
    }
}

extension ServicesProvider: StakeCoordinatorDependencyProvider {
    func stakeService() -> StakeServiceProtocol {
        StakeService(networkManager: _networkManager, mobileWallet: _mobileWallet)
    }
}

extension ServicesProvider: LoginDependencyProvider {
    func appSettingsService() -> AppSettingsService {
        AppSettingsService(networkManager: _networkManager)
    }
    
    func keychainWrapper() -> KeychainWrapperProtocol {
        _keychainWrapper
    }
    
    func recoveryPhraseService() -> RecoveryPhraseService {
        RecoveryPhraseService(
            keychainWrapper: _keychainWrapper,
            mobileWallet: _seedMobileWallet
        )
    }
    
    func seedMobileWallet() -> SeedMobileWalletProtocol {
        _seedMobileWallet
    }
}
