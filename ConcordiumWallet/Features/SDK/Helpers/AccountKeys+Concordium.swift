//
//  AccountKeys+Concordium.swift
//  CryptoX
//
//  Created by Max on 05.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

extension AccountKeys {
    /// Convert legacy AccountKeys to the new AccountKeysJSON format.
    func toAccountKeysJSON() throws -> AccountKeysJSON {
        var newKeys: [String: AccountKeysJSON.CredentialKeys] = [:]

        for (keyIdx, keyList) in self.keys {
            let newCredentialKeys = AccountKeysJSON.CredentialKeys(
                keys: keyList.keys.reduce(into: [String: AccountKeysJSON.Key]()) { result, legacyKey in
                    let newKeyIdx = String(legacyKey.key)
                    let newKey = AccountKeysJSON.Key(
                        signKey: legacyKey.value.signKey ?? "",
                        verifyKey: legacyKey.value.verifyKey ?? ""
                    )
                    result[newKeyIdx] = newKey
                }
            )
            newKeys[String(keyIdx)] = newCredentialKeys
        }

        return AccountKeysJSON(keys: newKeys)
    }
}
