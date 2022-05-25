//
//  Portfolio.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.05.2022.
//

import Foundation

struct PortfolioAsset {
    
    var code: String = ""
    var exchange: String = ""
    var name: String = ""
    var type: AssetType = .stock
    var country: String = ""
    var currency: String = "USD"
    var currentPrice: Double = 0
    var priceChange: Double = 0
    var priceChangePercent: Double = 0
    var logo: URL?
    var chartData: [Double]?
    
}
