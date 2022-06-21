//
//  StorageManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.05.2022.
//

import UIKit
import CoreData

class StorageManager {
    
    static let shared = StorageManager()
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private init() {}
    
    var fetchedResultsController: NSFetchedResultsController<Asset> {
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Asset.type),
                                    ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: "type",
            cacheName: nil)
        return fetchedResultsController
    }
    
    func performFetch(fetchedResultsController: NSFetchedResultsController<Asset>) {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
    }
    
    func getAllAssets() -> [Asset] {
        do {
            let assets = try context.fetch(Asset.fetchRequest())
            return assets
        } catch {
            print("Could not get all assets. \(error.localizedDescription).")
            return [Asset]()
        }
    }
    
    func getUSStockAssets() -> [Asset] {
        fetchedResultsController.fetchedObjects?.filter({ $0.type == .stock && $0.exchange == "US"}) ?? [Asset]()
    }
    
    func getCryptoAssets() -> [Asset] {
        fetchedResultsController.fetchedObjects?.filter({ $0.type == .crypto}) ?? [Asset]()
    }
    
    func saveAsset(code: String, exchange: String, type: AssetType, name: String) {
        let asset = Asset(context: context)
        asset.uid = [code, exchange].joined(separator: ":")
        asset.code = code
        asset.exchange = exchange
        asset.type = type
        asset.name = name
        
        do {
            try context.save()
        } catch {
            print("Could not save. \(error.localizedDescription).")
        }
    }
    
    func saveAllAssetData(code: String, exchange: String, type: AssetType, currentPrice: Double, priceChange: Double, priceChangePercent: Double, name: String, logo: String, currency: String, country: String, chartData: [Double]) {
        let asset = Asset(context: context)
        asset.uid = [code, exchange].joined(separator: ":")
        asset.code = code
        asset.exchange = exchange
        asset.type = type
        asset.currentPrice = currentPrice
        asset.priceChange = priceChange
        asset.priceChangePercent = priceChangePercent
        asset.name = name
        asset.logo = logo
        asset.currency = currency
        asset.country = country
        asset.chartData = chartData
        
        do {
            try context.save()
        } catch {
            print("Could not save. \(error.localizedDescription).")
        }
    }

    func getAsset(code: String, exchange: String) -> Asset? {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        let uid = [code, exchange].joined(separator: ":")
        let predicate = NSPredicate(format: "uid = %@", uid)
        
        request.predicate = predicate
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Could not check for favourite. \(error.localizedDescription).")
        }
        return nil
    }
    
    func deleteAsset(asset: Asset) {
        context.delete(asset)
        
        do {
            try context.save()
        } catch {
            print("Could not delete. \(error.localizedDescription).")
        }
    }
    
    func checkAssetIsFavourite(code: String, exchange: String) -> Bool {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        
        let predicate = NSPredicate(format: "code = %@ AND exchange = %@", code, exchange)
        
        request.predicate = predicate
        
        do {
            let count = try context.count(for: request)
            if count != 0 {
                return true
            } else {
                return false
            }
        } catch {
            print("Could not check for favorite. \(error.localizedDescription).")        }
        return false
    }
    
}
