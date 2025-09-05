//
//  StateEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension StateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StateEntity> {
        return NSFetchRequest<StateEntity>(entityName: "StateEntity")
    }

    @NSManaged public var denyList: Bool
    @NSManaged public var allowList: Bool

}

extension StateEntity : Identifiable {

}
