//
//  RealmHelper.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 11.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import RealmSwift

struct RealmHelper {
    
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).

    private static let schemaVersion: UInt64 = 21
    
    static let realmConfiguration = Realm.Configuration(
        schemaVersion: schemaVersion,

        // Set the block which will be called automatically when opening a Realm with
        // a schema version lower than the one set above
        migrationBlock: { _, oldSchemaVersion in
            if oldSchemaVersion < schemaVersion {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
        })
}
