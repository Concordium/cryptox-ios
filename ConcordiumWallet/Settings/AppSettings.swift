//
// Created by Concordium on 13/03/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

protocol AppSettingsDelegate: AnyObject {
    func checkForAppSettings()
}

enum PasswordType: String {
    case passcode
    case password
}

enum UserDefaultKeys: String {
    case passwordType
    case biometricsEnabled
    case passwordChangeInProgress
    case dontShowMemoAlertWarning
    case pendingAccount
    case acceptedTermsHash
    case ignoreMissingKeysForIdsOrAccountsAtLogin
    case needsBackupWarning
    case lastKnownAppVersionSinceBackupWarning
    
    case lastKnownAppVersion
    
    case dismissedWarningIds
    case dismissedAlertIds
    
    case hasRunBefore
    case isImportedFromFile
    
    case lastSelectedAccountAddress
}

struct AppSettings {
    
    static var passwordType: PasswordType? {
        get {
            guard let string = UserDefaults.standard.string(forKey: UserDefaultKeys.passwordType.rawValue) else {
                return nil
            }
            return PasswordType.init(rawValue: string)
        }
        set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: UserDefaultKeys.passwordType.rawValue)
        }
    }

    static var biometricsEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.biometricsEnabled.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.biometricsEnabled.rawValue)
        }
    }

    static var passwordChangeInProgress: Bool {
        get {
            if UserDefaults.standard.object(forKey: UserDefaultKeys.passwordChangeInProgress.rawValue) == nil {
                AppSettings.passwordChangeInProgress = false
            }
            return UserDefaults.standard.bool(forKey: UserDefaultKeys.passwordChangeInProgress.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.passwordChangeInProgress.rawValue)
        }
    }
    
    static var dontShowMemoAlertWarning: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.dontShowMemoAlertWarning.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.dontShowMemoAlertWarning.rawValue)
        }
    }
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    static var acceptedTermsHash: String? {
        get {
            UserDefaults.standard.string(forKey: UserDefaultKeys.acceptedTermsHash.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.acceptedTermsHash.rawValue)
        }
    }

    static var needsBackupWarning: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.needsBackupWarning.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.needsBackupWarning.rawValue)
        }
    }
    
    static var ignoreMissingKeysForIdsOrAccountsAtLogin: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.ignoreMissingKeysForIdsOrAccountsAtLogin.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.ignoreMissingKeysForIdsOrAccountsAtLogin.rawValue)
        }
    }

    static var lastKnownAppVersionSinceBackupWarning: String? {
        get {
            UserDefaults.standard.string(forKey: UserDefaultKeys.lastKnownAppVersionSinceBackupWarning.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.lastKnownAppVersionSinceBackupWarning.rawValue)
        }
    }
    
    static var iOSVersion: String { UIDevice.current.systemVersion }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}


extension AppSettings {
    static var lastKnownAppVersion: String? {
        get {
            UserDefaults.standard.string(forKey: UserDefaultKeys.lastKnownAppVersion.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.lastKnownAppVersion.rawValue)
        }
    }
    
    static var dismissedWarningIds: [String] {
        get {
            UserDefaults.standard.array(forKey: UserDefaultKeys.dismissedWarningIds.rawValue) as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.dismissedWarningIds.rawValue)
        }
    }
    
    static var dismissedAlertIds: [String] {
        get {
            UserDefaults.standard.array(forKey: UserDefaultKeys.dismissedAlertIds.rawValue) as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.dismissedAlertIds.rawValue)
        }
    }
    
    static var hasRunBefore: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.hasRunBefore.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.hasRunBefore.rawValue)
        }
    }
    
    static var isImportedFromFile: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.isImportedFromFile.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.isImportedFromFile.rawValue)
        }
    }
    
    static func removeImportedWalletSetings() {
        UserDefaults.removeObject(forKey: UserDefaultKeys.isImportedFromFile.rawValue)
        UserDefaults.removeObject(forKey: UserDefaultKeys.lastSelectedAccountAddress.rawValue)
    }
    
    static var lastSelectedAccountAddress: String? {
        get {
            UserDefaults.standard.string(forKey: UserDefaultKeys.lastSelectedAccountAddress.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.lastSelectedAccountAddress.rawValue)
        }
    }
}
