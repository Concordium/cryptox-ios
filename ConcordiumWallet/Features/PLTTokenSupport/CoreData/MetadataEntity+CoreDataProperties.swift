//
//  MetadataEntity+CoreDataProperties.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//
//

import Foundation
import CoreData


extension MetadataEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MetadataEntity> {
        return NSFetchRequest<MetadataEntity>(entityName: "MetadataEntity")
    }

    @NSManaged public var url: String

}

extension MetadataEntity : Identifiable {

}
