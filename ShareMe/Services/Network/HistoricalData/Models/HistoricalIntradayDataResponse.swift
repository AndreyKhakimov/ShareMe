//
//  HistoricalIntradayDataResponse.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 09.05.2022.
//

import Foundation

struct HistoricalIntradayDataResponse: Codable {
    let unixTimestamp: Int
    let dateTime: String
    let open, close, high, low: Double
    let volume: Int?

    enum CodingKeys: String, CodingKey {
        case unixTimestamp = "timestamp"
        case dateTime = "datetime"
        case open
        case close
        case high
        case low
        case volume
    }
}
