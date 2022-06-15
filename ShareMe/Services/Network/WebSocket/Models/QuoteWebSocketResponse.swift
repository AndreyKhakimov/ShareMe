//
//  QuoteWebSocketResponse.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 15.06.2022.
//

import Foundation

struct QuoteWebSocketResponse: Codable {
    let code: String
    let price: Double

    enum CodingKeys: String, CodingKey {
        case code = "s"
        case price = "ap"
    }
}

