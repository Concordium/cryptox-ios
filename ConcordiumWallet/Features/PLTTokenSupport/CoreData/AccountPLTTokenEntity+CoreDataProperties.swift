//
//  AccountPLTTokenEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension AccountPLTTokenEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountPLTTokenEntity> {
        return NSFetchRequest<AccountPLTTokenEntity>(entityName: "AccountPLTTokenEntity")
    }

    @NSManaged public var accountAddress: String
    @NSManaged public var token: PLTTokenEntity
    @NSManaged public var tokenAccountState: TokenAccountStateEntity

}

extension AccountPLTTokenEntity : Identifiable {

}
