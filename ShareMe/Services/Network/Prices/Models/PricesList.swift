//
//  PricesList.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 18.04.2022.
//

import Foundation

struct PricesList: Codable {
    let closePrices: [Double]
    let highPrices: [Double]
    let lowPrices: [Double]
    let openPrices: [Double]
    // status of the response: "ok" or "no_data"
    let status: String
    // time points for the prices list
    let timeStamp: [Int]
    let volumeData: [Int]
    
    var description: String {
        """
        closePrices: \(closePrices.description)
        highPrices: \(highPrices.description)
        lowPrices \(lowPrices.description)
        openPrices  \(openPrices.description)
        status \(status)
        timeStamp \(timeStamp.description)
        volumeData \(volumeData.description)
        """
    }
    
    enum CodingKeys: String, CodingKey {
        case closePrices = "c"
        case highPrices = "h"
        case lowPrices = "l"
        case openPrices = "o"
        case status = "s"
        case timeStamp = "t"
        case volumeData = "v"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.closePrices = try container.decode([Double].self, forKey: .closePrices)
        self.highPrices = try container.decode([Double].self, forKey: .highPrices)
        self.lowPrices = try container.decode([Double].self, forKey: .lowPrices)
        self.openPrices = try container.decode([Double].self, forKey: .openPrices)
        self.status = try container.decode(String.self, forKey: .status)
        self.timeStamp = try container.decode([Int].self, forKey: .timeStamp)
        self.volumeData = try container.decode([Int].self, forKey: .volumeData)
    }
}


