//
//  TokenAccountStateEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension TokenAccountStateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TokenAccountStateEntity> {
        return NSFetchRequest<TokenAccountStateEntity>(entityName: "TokenAccountStateEntity")
    }

    @NSManaged public var balance: TokenBalanceEntity
    @NSManaged public var state: StateEntity?

}

extension TokenAccountStateEntity : Identifiable {

}
