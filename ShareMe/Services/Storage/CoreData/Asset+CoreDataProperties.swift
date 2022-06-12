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
    @NSManaged public var currentPrice: Double
    @NSManaged public var priceChange: Double
    @NSManaged public var priceChangePercent: Double
    @NSManaged public var name: String
    @NSManaged public var logo: String
    @NSManaged public var currency: String
    @NSManaged public var country: String
    @NSManaged public var chartData: [Double]
    
    func update(with jsonDictionary: [String: Any]) throws {
        guard let uid = jsonDictionary["uid"] as? String,
              let code = jsonDictionary["code"] as? String,
              let exchange = jsonDictionary["exchange"] as? String,
              let type = jsonDictionary["type"] as? AssetType,
              let currentPrice = jsonDictionary["currentPrice"] as? Double,
              let priceChange = jsonDictionary["priceChange"] as? Double,
              let priceChangePercent = jsonDictionary["priceChangePercent"] as? Double,
              let name = jsonDictionary["name"] as? String,
              let logo = jsonDictionary["logo"] as? String,
              let currency = jsonDictionary["currency"] as? String,
              let country = jsonDictionary["country"] as? String,
              let chartData = jsonDictionary["chartData"] as? [Double]
        else {
            throw NSError(domain: "", code: 100, userInfo: nil)
        }
        
        self.uid = uid
        self.code = code
        self.exchange = exchange
        self.type = type
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.priceChangePercent = priceChangePercent
        self.name = name
        self.logo = logo
        self.currency = currency
        self.country = country
        self.chartData = chartData
    }
    
}

extension Asset : Identifiable {
    
}
