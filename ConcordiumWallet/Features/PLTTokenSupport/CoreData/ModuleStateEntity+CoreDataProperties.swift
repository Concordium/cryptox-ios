//
//  ModuleStateEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension ModuleStateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ModuleStateEntity> {
        return NSFetchRequest<ModuleStateEntity>(entityName: "ModuleStateEntity")
    }

    @NSManaged public var allowList: Bool
    @NSManaged public var burnable: Bool
    @NSManaged public var denyList: Bool
    @NSManaged public var mintable: Bool
    @NSManaged public var name: String
    @NSManaged public var governanceAccount: GovernanceAccountEntity
    @NSManaged public var metadata: MetadataEntity

}

extension ModuleStateEntity : Identifiable {

}
