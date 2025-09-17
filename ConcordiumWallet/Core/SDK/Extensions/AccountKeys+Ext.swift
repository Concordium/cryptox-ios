//
//  AccountKeys+Ext.swift
//  CryptoX
//
//  Created by Max on 23.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

extension AccountKeys {

    func toAccountKeyDictionary() throws -> [Concordium.CredentialIndex: [Concordium.KeyIndex: AccountKeyCurve25519]] {
        var result: [Concordium.CredentialIndex: [Concordium.KeyIndex: AccountKeyCurve25519]] = [:]

        for (credIdxString, credKeys) in self.keys {
            let credIdx = Concordium.CredentialIndex(UInt8(credIdxString))
            var keysDict: [Concordium.KeyIndex: AccountKeyCurve25519] = [:]

            for pair in credKeys.keys {
                let keyIdx = Concordium.KeyIndex(UInt8(pair.key))

                let jsonKey = AccountKeysJSON.Key(
                    signKey: pair.value.signKey!,
                    verifyKey: pair.value.verifyKey!
                )

                keysDict[keyIdx] = try jsonKey.toSDKType()
            }

            result[credIdx] = keysDict
        }

        return result
    }

}
