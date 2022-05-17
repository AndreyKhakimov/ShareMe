//
//  CurrentPrice.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import Foundation

struct Quote: Decodable {
    let code: String
    let time: Int
    let currentPrice: Double
    let change: Double
    let changePercent: Double
    
    var currentDate: String {
        let date = Date(timeIntervalSince1970: Double(time))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.medium
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }

    var description: String {
        """
    Current Price: \(currentPrice)
    Time: \(currentDate)
    """
    }
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case time = "timestamp"
        case currentPrice = "close"
        case change
        case changePercent = "change_p"
    }
}
