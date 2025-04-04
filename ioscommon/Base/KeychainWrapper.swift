//
//  KeychainWrapper.swift
//  ConcordiumWallet
//
//  Created by Concordium on 18/02/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import LocalAuthentication
import Security
import CryptoKit
import Combine
import CommonCrypto

protocol KeychainWrapperProtocol {
    func hasValue(key: String) -> Bool
    
    func store(key: String, value: String, securedByPassword password: String) -> Result<Void, KeychainError>
    func getValue(for key: String, securedByPassword password: String) -> Result<String, KeychainError>
    
    func getValueWithBiometrics(for key: String) -> AnyPublisher<String, KeychainError>
    func storeWithBiometrics(key: String, value: String) -> AnyPublisher<Void, KeychainError>
    
    func deleteKeychainItem(withKey key: String) -> Result<Void, KeychainError>
}

extension KeychainWrapperProtocol {
    private var saltKey: String { "password_salt" }
    private var passwordCheckKey: String { KeychainKeys.loginPassword.rawValue }
    private var biometricKey: String { KeychainKeys.password.rawValue }

    /// Hashes a password using PBKDF2 + SHA512 and returns hex string
    func hashPassword(_ password: String) -> String {
        let salt = getOrCreateSalt()

        guard let hashData = pbkdf2Hash(password: password, salt: salt) else {
            return ""
        }

        return hashData.map { String(format: "%02x", $0) }.joined()
    }

    /// Stores password by saving a known value ("passwordcheck") protected by the password-derived key
    func storePassword(password: String) -> Result<String, KeychainError> {
        let hash = hashPassword(password)
        return store(
            key: passwordCheckKey,
            value: "passwordcheck",
            securedByPassword: hash
        ).map { _ in hash }
    }

    /// Verifies password hash by checking if the known value can be unlocked
    func checkPasswordHash(pwHash: String) -> Result<Bool, KeychainError> {
        getValue(for: passwordCheckKey, securedByPassword: pwHash)
            .map { $0 == "passwordcheck" }
            .flatMap { isMatch in
                isMatch ? .success(true) : .failure(.wrongPassword)
            }
    }

    /// Verifies the password by hashing it and comparing
    func checkPassword(password: String) -> Result<Bool, KeychainError> {
        checkPasswordHash(pwHash: hashPassword(password))
    }

    /// Checks if password has ever been stored
    func passwordCreated() -> Bool {
        hasValue(key: passwordCheckKey)
    }

    /// Stores password hash with biometrics
    func storePasswordBehindBiometrics(pwHash: String) -> AnyPublisher<Void, KeychainError> {
        deleteKeychainItem(withKey: biometricKey)
            .publisher
            .flatMap { _ in
                self.storeWithBiometrics(key: biometricKey, value: pwHash)
            }
            .eraseToAnyPublisher()
    }

    /// Retrieves password hash with biometrics
    func getPasswordWithBiometrics() -> AnyPublisher<String, KeychainError> {
        getValueWithBiometrics(for: biometricKey)
    }

    // MARK: - Helpers

    /// Returns salt from Keychain or creates and stores one
    private func getOrCreateSalt() -> Data {
        if let savedSalt = load(key: saltKey) {
            return savedSalt
        }

        let newSalt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        save(newSalt, key: saltKey)
        return newSalt
    }

    /// Low-level PBKDF2 implementation using CommonCrypto
    private func pbkdf2Hash(password: String, salt: Data, keyByteCount: Int = 64, rounds: Int = 10_000) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }

        var derivedKey = Data(repeating: 0, count: keyByteCount)
        let result = derivedKey.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password, passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress!, salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
                    UInt32(rounds),
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress!, keyByteCount
                )
            }
        }

        return result == kCCSuccess ? derivedKey : nil
    }
    
    func save(_ data: Data, key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Remove any existing item first
        SecItemAdd(query as CFDictionary, nil)
    }

    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess else { return nil }
        return dataTypeRef as? Data
    }
}

enum KeychainError: Error {
    case invalidInput
    case noPassword
    case unexpectedPasswordData
    case unexpectedItemData
    case passwordNotFound
    case wrongPassword
    case itemNotFound
    case userCancelled
    case unhandledError(status: OSStatus)
}

enum KeychainKeys: String {
    case loginPassword
    case password
    case oldPassword // Old password is keept in keychain while re-encrypting all accounts (resume process on failure).
}

extension KeychainWrapper: KeychainWrapperProtocol {
    func hasValue(key: String) -> Bool {
        keychainItemExists(forKey: key)
    }
    
    func getValueWithBiometrics(for key: String) -> AnyPublisher<String, KeychainError> {
        return Future { completion in
            let result = getKeychainItem(withKey: key, password: nil)
                .flatMap { data -> Result<String, KeychainError> in
                    if let value = String(data: data, encoding: .utf8) {
                        return .success(value)
                    } else {
                        return .failure(.unexpectedItemData)
                    }
                }
            
            completion(result)
        }.eraseToAnyPublisher()
    }
    
    func storeWithBiometrics(key: String, value: String) -> AnyPublisher<Void, KeychainError> {
        if let data = value.data(using: .utf8) {
            return Future { completion in
                completion(setKeychainItem(withKey: key, itemData: data, password: nil))
            }.eraseToAnyPublisher()
        } else {
            return .fail(.invalidInput)
        }
    }
    
    func store(key: String, value: String, securedByPassword password: String) -> Result<Void, KeychainError> {
        let data = value.data(using: .utf8)!
        return setKeychainItem(withKey: key, itemData: data, password: password)
    }

    func getValue(for key: String, securedByPassword password: String) -> Result<String, KeychainError> {
        getKeychainItem(withKey: key, password: password).flatMap {
            guard let result = String(data: $0, encoding: .utf8) else {
                return .failure(KeychainError.unexpectedItemData)
            }
            return .success(result)
        }
    }
}

struct KeychainWrapper {
    private let passwordCheck = "passwordcheck"

    private enum KeychainService: String {
        case concordiumWallet = "ConcordiumWallet"
    }

    private func keychainItemExists(forKey key: String) -> Bool {
        var query = keychainQuery(withKey: key)
        query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        let res = SecItemCopyMatching(query as CFDictionary, nil)
        return res == errSecInteractionNotAllowed || res == errSecSuccess
    }

    /**
    * password: If nil, data is stored using biometrics
    */
    private func setKeychainItem(withKey key: String, itemData: Data, password: String?) -> Result<Void, KeychainError> {
        var query = keychainQuery(withKey: key)

        let access: SecAccessControl?
        if let password = password {
            access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, .applicationPassword, nil)

            let localAuthenticationContext = LAContext()
            let theApplicationPassword = password.data(using: .utf8)
            _ = localAuthenticationContext.setCredential(theApplicationPassword, type: .applicationPassword)

            // This does not work on simulator :-( https://stackoverflow.com/questions/53341248
            #if !targetEnvironment(simulator)
            query[kSecUseAuthenticationContext as String] = localAuthenticationContext
            #endif
        } else {
            access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, .biometryCurrentSet, nil)
        }
        query[kSecAttrAccessControl as String] = access as AnyObject?

        if keychainItemExists(forKey: key) {
            _ = deleteKeychainItem(withKey: key)
        }

        query[kSecValueData as String] = itemData as AnyObject?
        let result = SecItemAdd(query as CFDictionary, nil)
        if result != errSecSuccess {
            return .failure(mapKeychainError(error: result))
        }
        return .success(Void())
    }

    private func getKeychainItem(withKey key: String, password: String?) -> Result<Data, KeychainError> {
        var query = keychainQuery(withKey: key)

        let access: SecAccessControl?
        if let password = password {
            access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, .applicationPassword, nil)

            let localAuthenticationContext = LAContext()
            let theApplicationPassword = password.data(using: .utf8)
            _ = localAuthenticationContext.setCredential(theApplicationPassword, type: .applicationPassword)

            // This does not work on simulator :-( https://stackoverflow.com/questions/53341248
            #if !targetEnvironment(simulator)
            query[kSecUseAuthenticationContext as String] = localAuthenticationContext
            #endif
        } else {
            let localAuthenticationContext = LAContext()
            let pwType = AppSettings.passwordType?.rawValue ?? PasswordType.passcode.rawValue
            localAuthenticationContext.localizedCancelTitle = "keychain.popup.button.enter\(pwType)".localized
            query[kSecUseAuthenticationContext as String] = localAuthenticationContext
            access = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlocked, .biometryCurrentSet, nil)
        }

        query[kSecAttrAccessControl as String] = access as AnyObject?
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &item)
        if result != errSecSuccess {
            return .failure(mapKeychainError(error: result))
        }

        guard
            let resultsDict = item as? [String: Any],
            let resultsData = resultsDict[kSecValueData as String] as? Data
            else { return .failure(.unexpectedItemData) }
        return .success(resultsData)
    }

    public func deleteKeychainItem(withKey key: String) -> Result<Void, KeychainError> {
        let query = keychainQuery(withKey: key)
        let result = SecItemDelete(query as CFDictionary)
        if result != errSecSuccess && result != errSecItemNotFound {
            return .failure(mapKeychainError(error: result))
        }
        return .success(Void())
    }

    private func keychainQuery(withKey key: String?) -> [String: AnyObject] {
        var query = [String: AnyObject]()

        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = KeychainService.concordiumWallet.rawValue as AnyObject?
        query[kSecAttrAccessGroup as String] = nil

        if let key = key {
            query[kSecAttrAccount as String] = key as AnyObject?
        }
        return query
    }

    private func mapKeychainError(error: OSStatus) -> KeychainError {

        switch error {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecAuthFailed:
            return .wrongPassword
        case errSecUserCanceled:
            return .userCancelled
        default:
            break
        }

        return .unhandledError(status: error)
    }
}
