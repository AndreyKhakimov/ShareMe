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
    let close: Double
    let volume: Int

    enum CodingKeys: String, CodingKey {
        case unixTimestamp = "timestamp"
        case dateTime = "datetime"
        case close
        case volume
    }
}
