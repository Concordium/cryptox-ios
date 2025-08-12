//
//  PLTTokenEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension PLTTokenEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PLTTokenEntity> {
        return NSFetchRequest<PLTTokenEntity>(entityName: "PLTTokenEntity")
    }

    @NSManaged public var accountAddress: String
    @NSManaged public var tokenId: String
    @NSManaged public var tokenState: TokenStateEntity

}

extension PLTTokenEntity : Identifiable {

}
