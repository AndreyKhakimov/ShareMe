//
//  HistoricalDataRespond.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 27.04.2022.
//

import Foundation

struct HistoricalDataRespond: Codable {
    let date: String
    let open, high, low, close: Double
    let volume: Int
    
    var descriprion: String {
        "Date: \(date)\n Open \(open), Close \(close)"
    }
}
