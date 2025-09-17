//
//  TotalSupplyEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension TotalSupplyEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TotalSupplyEntity> {
        return NSFetchRequest<TotalSupplyEntity>(entityName: "TotalSupplyEntity")
    }

    @NSManaged public var decimals: Int16
    @NSManaged public var value: String?

}

extension TotalSupplyEntity : Identifiable {

}
