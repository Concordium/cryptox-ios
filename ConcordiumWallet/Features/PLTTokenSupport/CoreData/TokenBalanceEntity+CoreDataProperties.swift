//
//  TokenBalanceEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension TokenBalanceEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TokenBalanceEntity> {
        return NSFetchRequest<TokenBalanceEntity>(entityName: "TokenBalanceEntity")
    }

    @NSManaged public var decimals: Int16
    @NSManaged public var value: String?

}

extension TokenBalanceEntity : Identifiable {

}
