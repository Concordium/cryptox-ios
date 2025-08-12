//
//  TokenStateEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension TokenStateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TokenStateEntity> {
        return NSFetchRequest<TokenStateEntity>(entityName: "TokenStateEntity")
    }

    @NSManaged public var decimals: Int16
    @NSManaged public var tokenModuleRef: String
    @NSManaged public var moduleState: ModuleStateEntity
    @NSManaged public var totalSupply: TotalSupplyEntity

}

extension TokenStateEntity : Identifiable {

}
