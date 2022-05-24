//
//  AssetMapping.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 23.05.2022.
//

import CoreData

class AssetMapping: NSEntityMigrationPolicy {
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        
        guard let dInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first else {
            fatalError("destinationAsset creating issue")
        }
        
        let uid = [sInstance.primitiveValue(forKey: "code") as! String, sInstance.primitiveValue(forKey: "exchange") as! String].joined(separator: ":")
        
        dInstance.setValue(uid, forKey: "uid")

//        if sInstance.entity.name == "Asset" {
////            let uid = sInstance.primitiveValue(forKey: "uid") as! String
//            let code = sInstance.primitiveValue(forKey: "code") as! String
//            let exchange = sInstance.primitiveValue(forKey: "exchange") as! String
//            let type = sInstance.primitiveValue(forKey: "type") as! Int16
//            
//        }
    }
}
