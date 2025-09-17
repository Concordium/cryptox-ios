//
//  GovernanceAccountEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension GovernanceAccountEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GovernanceAccountEntity> {
        return NSFetchRequest<GovernanceAccountEntity>(entityName: "GovernanceAccountEntity")
    }

    @NSManaged public var address: String
    @NSManaged public var type: String

}

extension GovernanceAccountEntity : Identifiable {

}
