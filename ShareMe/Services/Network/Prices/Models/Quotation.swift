//
//  Quote.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.04.2022.
//

import Foundation

struct Quotation: Codable {
    let currentPrice: Double
    let dailyChange: Double
    let dailyPercentChange: Double
    let dailyHighPrice: Double
    let dailyLowPrice: Double
    let dailyOpenPrice: Double
    let previousClosePrice: Double
    let time: Int
    var currentDate: String {
        let date = Date(timeIntervalSince1970: Double(time))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    var description: String {
        """
    Current Price: \(currentPrice)
    Daily Change: \(dailyChange)
    Daily Percent Change: \(dailyPercentChange)
    Daily High Price: \(dailyHighPrice)
    Daily Low Price: \(dailyLowPrice)
    Daily Open Price: \(dailyOpenPrice)
    Previous Close Price: \(previousClosePrice)
    Time: \(currentDate)
    """
    }
    
    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"
        case dailyChange = "d"
        case dailyPercentChange = "dp"
        case dailyHighPrice = "h"
        case dailyLowPrice = "l"
        case dailyOpenPrice = "o"
        case previousClosePrice = "pc"
        case time = "t"
        
    }
}

