import Foundation
import RealmSwift

protocol StorageManagerProtocol {
    func storeIdentity(_: IdentityDataType) throws
    func getIdentities() -> [IdentityDataType]
    func getIdentity(matchingIdentityObject identityObject: IdentityObject) -> IdentityDataType?
    func getIdentity(matchingSeedIdentityObject seedIdentityObject: SeedIdentityObject) -> IdentityDataType?
    func getConfirmedIdentities() -> [IdentityDataType]
    func getPendingIdentities() -> [IdentityDataType]
    func getFailedIdentities() -> [IdentityDataType]
    func removeIdentity(_ identity: IdentityDataType?)
    
    func storePrivateIdObjectData(_: PrivateIDObjectData, pwHash: String) -> Result<String, Error>
    func getPrivateIdObjectData(key: String, pwHash: String) -> Result<PrivateIDObjectData, KeychainError>
    /// Remove the private ID object data stored in the keychain with the associated key
    func removePrivateIdObjectData(key: String)

    func storePrivateAccountKeys(_ privateAccountKeys: AccountKeys, pwHash: String) -> Result<String, Error>
    func getPrivateAccountKeys(key: String, pwHash: String) -> Result<AccountKeys, Error>
    /// Remove the private account keys stored in the keychain with the associated key
    func removePrivateAccountKeys(key: String)
    func updatePrivateAccountDataPasscode(for account: AccountDataType, accountData: AccountKeys, pwHash: String) -> Result<Void, Error>
    
    func storePrivateEncryptionKey(_ privateKey: String, pwHash: String) -> Result<String, Error>
    func getPrivateEncryptionKey(key: String, pwHash: String) -> Result<String, Error>
    /// Remove the private encryptioni key stored in the keychain with the associated key
    func removePrivateEncryptionKey(key: String)
    func updatePrivateEncryptionKeyPasscode(for account: AccountDataType, privateKey: String, pwHash: String) -> Result<Void, Error>

    func storeCommitmentsRandomness(_ commitmentsRandomness: CommitmentsRandomness, pwHash: String) -> Result<String, Error>
    func getCommitmentsRandomness(key: String, pwHash: String) -> Result<CommitmentsRandomness, Error>
    // swiftlint:disable line_length
    func updateCommitmentsRandomnessPasscode(for account: AccountDataType, commitmentsRandomness: CommitmentsRandomness, pwHash: String) -> Result<Void, Error>
    
    func getNextAccountNumber(for identity: IdentityDataType) -> Result<Int, StorageError>
    func storeAccount(_ account: AccountDataType) throws -> AccountDataType
    func getAccounts() -> [AccountDataType]
    func getWallets() -> [ExportRecipient]
    func getAccounts(for identity: IdentityDataType) -> [AccountDataType]
    func getAccount(withAddress: String) -> AccountDataType?
    func removeAccount(account: AccountDataType?)
    
    func storeShieldedAmount(amount: ShieldedAmountType) throws  -> ShieldedAmountType
    func getShieldedAmountsForAccount(_ account: AccountDataType) -> [ShieldedAmountType]
    func getShieldedAmount(encryptedValue: String, account: AccountDataType) -> ShieldedAmountType?

    @discardableResult func storeRecipient(_ recipient: RecipientDataType) throws -> RecipientDataType
    func editRecipient(oldRecipient: RecipientDataType, newRecipient: RecipientDataType) throws
    func getRecipients() -> [RecipientDataType]
    func getRecipient(withAddress address: String) -> RecipientDataType?
    func getRecipient(withName: String, address: String) -> RecipientDataType?
    func removeRecipient(_ recipient: RecipientDataType?)

    func storeTransfer(_ transfer: TransferDataType) throws -> TransferDataType
    func getTransfers(for accountAddress: String) -> [TransferDataType]
    func getLastEncryptedBalanceTransfer(for accountAddress: String) -> TransferDataType?
    func getAllTransfers() -> [TransferDataType]
    func removeTransfer(_ transfer: TransferDataType?)
    
    func removeUnfinishedIdentities()
    func removeUnfinishedAccounts()
    func removeAccountsWithoutAddress()
    func removeUnfinishedAccountsAndRelatedIdentities()
    
    func getPendingAccountsAddresses() -> [String]
    func storePendingAccount(with address: String)
    func removePendingAccount(with address: String)
    
    func removeAllPendingAccount()

    func updateChainParms(_ chainParams: ChainParametersDataType) throws -> ChainParametersDataType
    func getChainParams() -> ChainParametersEntity?
    
    func getAccountSavedCIS2Tokens(_ address: String) -> [CIS2Token]
    func storeCIS2Token(token: CIS2Token, address: String) throws
    func subscribeCIS2TokensUpdate(_ address: String) -> RealmPublishers.WillChange<Results<CIS2TokenEntity>>
    func removeCIS2Token(token: CIS2Token, address: String) throws
    
    func removeAllAccounts() throws
}

enum StorageError: Error {
    case writeError(error: Error)
    case itemNotFound
    case nullDataError
}

class StorageManager: StorageManagerProtocol {
    private var realm: Realm
    private var keychain: KeychainWrapperProtocol

    init(
        keychain: KeychainWrapperProtocol,
        configuration: Realm.Configuration = RealmHelper.realmConfiguration
    ) {
        self.keychain = keychain
        self.realm = try! Realm(configuration: configuration) // swiftlint:disable:this force_try
        LegacyLogger.debug("Initialized Realm database at \(realm.configuration.fileURL?.absoluteString ?? "")")
        excludeDocumentsAndLibraryFoldersFromBackup()
    }

    // MARK: Identity
    func storeIdentity(_ identity: IdentityDataType) throws {
        guard let identityEntity = identity as? IdentityEntity else {
            return
        }
        
        try realm.write {
            realm.add(identityEntity)
        }
    }

    func getIdentities() -> [IdentityDataType] {
        return Array(realm.objects(IdentityEntity.self))
    }

    // swiftlint:disable line_length
    func getIdentity(matchingIdentityObject identityObject: IdentityObject) -> IdentityDataType? {
        getIdentities().first { $0.identityObject?.preIdentityObject.pubInfoForIP.idCredPub == identityObject.preIdentityObject.pubInfoForIP.idCredPub }
    }
    
    func getIdentity(matchingSeedIdentityObject seedIdentityObject: SeedIdentityObject) -> IdentityDataType? {
        getIdentities().first {
            $0.seedIdentityObject?.preIdentityObject.idCredPub == seedIdentityObject.preIdentityObject.idCredPub
        }
    }

    func getConfirmedIdentities() -> [IdentityDataType] {
        return Array(realm.objects(IdentityEntity.self).filter("stateString == '\(IdentityState.confirmed.rawValue)'"))
    }

    func getPendingIdentities() -> [IdentityDataType] {
        return Array(realm.objects(IdentityEntity.self).filter("stateString == '\(IdentityState.pending.rawValue)'"))
    }

    func getFailedIdentities() -> [IdentityDataType] {
        return Array(realm.objects(IdentityEntity.self).filter("stateString == '\(IdentityState.failed.rawValue)'"))
    }
    
    func storePrivateIdObjectData(_ privateIdObjectData: PrivateIDObjectData, pwHash: String) -> Result<String, Error> {
        let id = UUID().uuidString
        do {
            guard let jsonData = try privateIdObjectData.jsonString() else { return .failure(StorageError.nullDataError) }
            return keychain.store(key: id, value: jsonData, securedByPassword: pwHash)
                    .map { _ in id }
                    .mapError { $0 as Error }
        } catch {
            return .failure(error)
        }
    }

    func getPrivateIdObjectData(key: String, pwHash: String) -> Result<PrivateIDObjectData, KeychainError> {
        keychain.getValue(for: key, securedByPassword: pwHash)
            .flatMap {
                do {
                    return try .success(PrivateIDObjectData($0))
                } catch {
                    return .failure(KeychainError.itemNotFound)
                }
            }
    }
    
    /// Remove the private ID object data stored in the keychain with the associated key
    func removePrivateIdObjectData(key: String) {
        _ = keychain.deleteKeychainItem(withKey: key)
    }
    
    func storePrivateEncryptionKey(_ privateKey: String, pwHash: String) -> Result<String, Error> {
        let id = UUID().uuidString
        return keychain.store(key: id, value: privateKey, securedByPassword: pwHash)
            .map { _ in id }
            .mapError { $0 as Error }
    }
    
    func getPrivateEncryptionKey(key: String, pwHash: String) -> Result<String, Error> {
        keychain.getValue(for: key, securedByPassword: pwHash)
        .mapError { $0 as Error }
    }
    
    /// Remove the private encryptioni key stored in the keychain with the associated key
    func removePrivateEncryptionKey(key: String) {
        _ = keychain.deleteKeychainItem(withKey: key)
    }
    
    func updatePrivateEncryptionKeyPasscode(for account: AccountDataType, privateKey: String, pwHash: String) -> Result<Void, Error> {
        if let privateEncryptionItemKey = account.encryptedPrivateKey {
            return keychain.store(key: privateEncryptionItemKey, value: privateKey, securedByPassword: pwHash)
                .mapError { $0 as Error }
        }
        return .success(Void())
    }
    
    func getNextAccountNumber(for identity: IdentityDataType) -> Result<Int, StorageError> {
        let identityEntity = identity as! IdentityEntity // swiftlint:disable:this force_cast
        let nextAccountNumber = identityEntity.accountsCreated
        do {
            try realm.write {
                identityEntity.accountsCreated += 1
            }
        } catch {
            return .failure(.writeError(error: error))
        }
        return .success(nextAccountNumber)
    }

    func removeIdentity(_ identity: IdentityDataType?) {
        guard let identityEntity = identity as? IdentityEntity else {
            return
        }
        try? realm.write {
            realm.delete(identityEntity)
        }
    }
    
    // MARK: Account
    func getAccounts() -> [AccountDataType] {
        Array(realm.objects(AccountEntity.self))
    }
    
    func getWallets() -> [ExportRecipient] {
        let realmW: Realm = try! Realm(configuration: RealmHelper.realmConfiguration)
        return realmW.objects(AccountEntity.self).map({ ExportRecipient(name: $0.displayName, address: $0.address) })
    }

    func getAccounts(for identity: IdentityDataType) -> [AccountDataType] {
        guard let identityId = (identity as? IdentityEntity)?.id else { return [] }
        return Array(realm.objects(AccountEntity.self).filter("identityEntity.id == %@", identityId))
    }

    func getAccount(withAddress address: String) -> AccountDataType? {
        realm.objects(AccountEntity.self).filter("address == %@", address).first
    }

    func storePrivateAccountKeys(_ privateAccountKeys: AccountKeys, pwHash: String) -> Result<String, Error> {
        let id = UUID().uuidString
        guard let jsonData = try? privateAccountKeys.jsonString() else { return .failure(StorageError.nullDataError) }
        return keychain.store(key: id, value: jsonData, securedByPassword: pwHash)
                .map { _ in id }
                .mapError { $0 as Error }
    }

    func getPrivateAccountKeys(key: String, pwHash: String) -> Result<AccountKeys, Error> {
        keychain.getValue(for: key, securedByPassword: pwHash)
                .flatMap {
                    do {
                        return try .success(AccountKeys($0))
                    } catch {
                        return .failure(KeychainError.itemNotFound)
                    }
                }
                .mapError { $0 as Error }
    }
    
    /// Remove the private account keys stored in the keychain with the associated key
    func removePrivateAccountKeys(key: String) {
        _ = keychain.deleteKeychainItem(withKey: key)
    }

    func updatePrivateAccountDataPasscode(for account: AccountDataType, accountData: AccountKeys, pwHash: String) -> Result<Void, Error> {
        guard let privateAccountDataItemKey = account.encryptedAccountData else { return .success(Void()) }
        guard let jsonData = try? accountData.jsonString() else { return .failure(StorageError.nullDataError) }
        return keychain.store(key: privateAccountDataItemKey, value: jsonData, securedByPassword: pwHash)
                .mapError { $0 as Error }
    }
        
    func storeAccount(_ account: AccountDataType) throws -> AccountDataType {
        if let accountEntity = account as? AccountEntity {
            do {
                try realm.write {
                    realm.add(accountEntity)
                }
            } catch {
                throw StorageError.writeError(error: error)
            }
        }
        return account
    }

    func removeAccount(account: AccountDataType?) {
        guard let accountEntity = account as? AccountEntity else {
            return
        }
        
        removePendingAccount(with: accountEntity.address)

        try? realm.write {
            realm.delete(accountEntity)
        }
    }

    func storeShieldedAmount(amount: ShieldedAmountType) throws  -> ShieldedAmountType {
        
        if let account = amount.account, let existingValue = getShieldedAmount(encryptedValue: amount.encryptedValue, account: account) {
            return existingValue
        }
        
        if let shieldedAmount = amount as? ShieldedAmountEntity {
            do {
                try realm.write {
                    realm.add(shieldedAmount)
                }
            } catch {
                throw StorageError.writeError(error: error)
            }
        }
        return amount
    }
    
    func getShieldedAmountsForAccount(_ account: AccountDataType) -> [ShieldedAmountType] {
        guard let accountId = (account as? AccountEntity)?.address else { return [] }
        return Array(realm.objects(ShieldedAmountEntity.self).filter("accountEntity.address == %@", accountId))
        
    }
    
    func getShieldedAmount(encryptedValue: String, account: AccountDataType) -> ShieldedAmountType? {
        guard let address = (account as? AccountEntity)?.address else { return nil }
        return Array(realm.objects(ShieldedAmountEntity.self).filter("primaryKey == %@", address + encryptedValue)).first
    }
    
    func storeCommitmentsRandomness(_ commitmentsRandomness: CommitmentsRandomness, pwHash: String) -> Result<String, Error> {
        let id = UUID().uuidString
        guard let jsonData = try? commitmentsRandomness.jsonString() else { return .failure(StorageError.nullDataError) }
        return keychain.store(key: id, value: jsonData, securedByPassword: pwHash)
                .map { _ in id }
                .mapError { $0 as Error}
    }
    
    func getCommitmentsRandomness(key: String, pwHash: String) -> Result<CommitmentsRandomness, Error> {
        keychain.getValue(for: key, securedByPassword: pwHash)
                .flatMap {
                    do {
                        return try .success(CommitmentsRandomness($0))
                    } catch {
                        return .failure(KeychainError.itemNotFound)
                    }
                }
            .mapError { $0 as Error }
    }
    
    func updateCommitmentsRandomnessPasscode(for account: AccountDataType, commitmentsRandomness: CommitmentsRandomness, pwHash: String) -> Result<Void, Error> {
        guard let commitmentsRandomnessItemKey = account.encryptedCommitmentsRandomness else { return .success(Void()) }
        guard let jsonData = try? commitmentsRandomness.jsonString() else { return .failure(StorageError.nullDataError) }
        return keychain.store(key: commitmentsRandomnessItemKey, value: jsonData, securedByPassword: pwHash)
                .mapError { $0 as Error }
    }
    
    // MARK: - Recipient
    func getRecipients() -> [RecipientDataType] {
        Array(realm.objects(RecipientEntity.self))
    }

    func getRecipient(withAddress address: String) -> RecipientDataType? {
        Array(realm.objects(RecipientEntity.self).filter("address == %@", address)).first
    }

    func getRecipient(withName name: String, address: String) -> RecipientDataType? {
        Array(realm.objects(RecipientEntity.self).filter("name == %@ AND address == %@", name, address)).first
    }

    @discardableResult
    func storeRecipient(_ recipient: RecipientDataType) throws -> RecipientDataType {
        if let recipientEntity = recipient as? RecipientEntity {
            do {
                try realm.write {
                    realm.add(recipientEntity)
                }
            } catch {
                throw StorageError.writeError(error: error)
            }
        }
        return recipient
    }

    func editRecipient(oldRecipient: RecipientDataType, newRecipient: RecipientDataType) throws {

        let recipientEntity = oldRecipient as! RecipientEntity // swiftlint:disable:this force_cast
        do {
            try realm.write {
                recipientEntity.name = newRecipient.name
                recipientEntity.address = newRecipient.address
            }
        } catch {
            throw StorageError.writeError(error: error)
        }
    }

    func removeRecipient(_ recipient: RecipientDataType?) {
        guard let recipientEntity = recipient as? RecipientEntity else {
            return
        }
        try? realm.write {
            realm.delete(recipientEntity)
        }
    }

    // MARK: Transfer
    func storeTransfer(_ transfer: TransferDataType) throws -> TransferDataType {
        if let transferEntity = transfer as? TransferEntity {
            do {
                try realm.write {
                    realm.add(transferEntity)
                }
            } catch {
                LegacyLogger.error("ERROR storing transfer \(transfer)")
                throw StorageError.writeError(error: error)
            }
        }
        return transfer
    }

    func getTransfers(for accountAddress: String) -> [TransferDataType] {
        let sentTransactions = NSPredicate(format: "fromAddress == %@", accountAddress)
        let gtuDrop = NSPredicate(format: "toAddress == %@ AND fromAddress == ''", accountAddress)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [sentTransactions, gtuDrop])
        let transactions: [TransferDataType] = Array(realm.objects(TransferEntity.self).filter(predicate))
        return transactions
    }

    func getAllTransfers() -> [TransferDataType] {
        Array(realm.objects(TransferEntity.self))
    }

    func getLastEncryptedBalanceTransfer(for accountAddress: String) -> TransferDataType? {
        let sentTransactions = NSPredicate(format: "fromAddress == %@", accountAddress)
        let noSimpleTransactions = NSPredicate(format: "transferTypeString != %@", "simpleTransfer")
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sentTransactions, noSimpleTransactions])
        let objects = realm.objects(TransferEntity.self).filter(predicate).sorted(byKeyPath: "createdAt", ascending: false)
        return objects.first
    }
    
    func removeTransfer(_ transfer: TransferDataType?) {
        guard let transferEntity = transfer as? TransferEntity else {
            return
        }
        try? realm.write {
            realm.delete(transferEntity)
        }
    }
    
    func removeUnfinishedIdentities() {
        let unfinishedIdentities = getIdentities().filter { $0.ipStatusUrl.isEmpty }
        for identity in unfinishedIdentities {
            removeIdentity(identity)
        }
    }
    
    func removeUnfinishedAccounts() {
        guard
            let unfinishedAccount = getAccounts().first(where: { $0.identity == nil || $0.identity?.ipStatusUrl == nil || $0.identity?.state == .failed })
        else {
            return
        }
        
        removeAccount(account: unfinishedAccount)
    }
    
    func removeAccountsWithoutAddress() {
        let accountsWithoutAddress = getAccounts().filter { $0.address == ""}
        for account in accountsWithoutAddress {
            removeAccount(account: account)
        }
    }
    
    func removeUnfinishedAccountsAndRelatedIdentities() {
        let unfinishedIdentities = getIdentities().filter { $0.ipStatusUrl.isEmpty }
        for identity in unfinishedIdentities {
            if let account = getAccounts(for: identity).first {
                removeAccount(account: account)
                removeIdentity(identity)
            }
        }
    }
    
    func getPendingAccountsAddresses() -> [String] {
        let key = UserDefaultKeys.pendingAccount.rawValue

        guard let pendingAccountsAddresses = UserDefaults.standard.stringArray(forKey: key) else {
            return []
        }
        
        return pendingAccountsAddresses
    }
    
    func storePendingAccount(with address: String) {
        let key = UserDefaultKeys.pendingAccount.rawValue

        if var pendingAccounts = UserDefaults.standard.stringArray(forKey: key) {
            guard !pendingAccounts.contains(where: { $0 == address }) else { return }
            pendingAccounts.append(address)
            UserDefaults.standard.set(pendingAccounts, forKey: key)
        } else {
            UserDefaults.standard.set([address], forKey: key)
        }
    }
    
    func removePendingAccount(with address: String) {
        let key = UserDefaultKeys.pendingAccount.rawValue
        
        guard var pendingAccounts = UserDefaults.standard.stringArray(forKey: key) else {
            return
        }
        
        pendingAccounts.removeAll(where: { $0 == address })
        UserDefaults.standard.set(pendingAccounts, forKey: key)
    }
    
    func removeAllPendingAccount() {
        let accountsAddresses = getPendingAccountsAddresses()
        
        for i in accountsAddresses {
            removePendingAccount(with: i)
        }
    }
    
    
    private func excludeDocumentsAndLibraryFoldersFromBackup() {
        let documentsPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var documentsDirectoryURL = documentsPaths[0]
        excludeFromBackup(url: &documentsDirectoryURL)
        
        let libraryPaths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        var libraryURL = libraryPaths[0]
        excludeFromBackup(url: &libraryURL)
    }
    
    private func excludeFromBackup(url:inout URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try url.setResourceValues(values)
        } catch let error {
            LegacyLogger.debug("Unable to exclude folder from backup due to error: \(error)")
        }
    }
    
    func updateChainParms(_ chainParams: ChainParametersDataType) throws -> ChainParametersDataType {
        if let existingChainParams = getChainParams() {
            try realm.write {
                existingChainParams.delegatorCooldown = chainParams.delegatorCooldown
                existingChainParams.poolOwnerCooldown = chainParams.poolOwnerCooldown
            }
            return existingChainParams
        }
        
        if let chainParamsEntity = chainParams as? ChainParametersEntity {
            do {
                try realm.write {
                    realm.add(chainParamsEntity)
                }
            } catch {
                LegacyLogger.error("ERROR storing chain params \(chainParams)")
                throw StorageError.writeError(error: error)
            }
        }
        return chainParams
    }
    func getChainParams() -> ChainParametersEntity? {
        Array(realm.objects(ChainParametersEntity.self)).first
    }
}

/// CIS2 tokens support
extension StorageManager {
    func getAccountSavedCIS2Tokens(_ address: String) -> [CIS2Token] {
        Array(realm.objects(CIS2TokenEntity.self).filter("accountOwnerAddress == '\(address)'")).map(CIS2Token.init(entity:))
    }
    
    func subscribeCIS2TokensUpdate(_ address: String) -> RealmPublishers.WillChange<Results<CIS2TokenEntity>> {
        realm.objects(CIS2TokenEntity.self).filter("accountOwnerAddress == '\(address)'").objectWillChange
    }
    
    func storeCIS2Token(token: CIS2Token, address: String) throws {
        do {
            try realm.write {
                realm.add(CIS2TokenEntity.init(token: token, address: address))
            }
        } catch {
            LegacyLogger.error("ERROR storing CIS2Token \(token)")
            throw StorageError.writeError(error: error)
        }
    }
    
    func removeCIS2Token(token: CIS2Token, address: String) throws {
        guard let entity = Array(realm.objects(CIS2TokenEntity.self).filter("accountOwnerAddress == '\(address)'").filter({ entity in
            entity.tokenId == token.tokenId && entity.index == token.contractAddress.index
        })).first else { throw StorageError.itemNotFound }
        
        try! realm.write {
            realm.delete(entity)
        }
    }
}

extension StorageManager {
    func removeAllAccounts() throws {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            LegacyLogger.error("ERROR wanishing realm \(error)")
        }
    }
}

extension StorageManagerProtocol {
    func getDelegationTransfers(for account: AccountDataType) -> [TransferDataType] {
        return getTransfers(for: account.address).filter { transfer in
            transfer.transferType.isDelegationTransfer
        }
    }
}

extension StorageManagerProtocol {
    func hasPendingBakerRegistration(for account: String) -> Bool {
        !getTransfers(for: account)
            .filter { $0.transferType.isBakingTransfer }
            .isEmpty
    }
}
