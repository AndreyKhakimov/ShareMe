//
//  SearchRespond.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import Foundation

struct SearchRespond: Decodable {
    let code: String
    let exchange: String
    let name: String
    let type: String
    let country: String
    let currency: String
    let isin: String?
    let previousClose: Double
    let previousCloseDate: String
    var logo: URL?
    var chartData: [Double]?
    
    var info: String {
        "\(name)"
    }
    
    var descriprion: String {
        "Exchange: \(exchange) \(country), \(previousClose) \(currency)"
    }
    
    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case exchange = "Exchange"
        case name = "Name"
        case type = "Type"
        case country = "Country"
        case currency = "Currency"
        case isin = "ISIN"
        case previousClose, previousCloseDate, logo
    }
    
}
