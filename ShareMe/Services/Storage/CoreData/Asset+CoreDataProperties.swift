//
//  Asset+CoreDataProperties.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.05.2022.
//
//

import Foundation
import CoreData


extension Asset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
        return NSFetchRequest<Asset>(entityName: "Asset")
    }

    @NSManaged public var uid: String
    @NSManaged public var code: String
    @NSManaged public var exchange: String
    @NSManaged public var type: AssetType

}

extension Asset : Identifiable {

}
