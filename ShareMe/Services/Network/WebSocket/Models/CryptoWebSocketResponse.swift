//
//  CryptoWebSocketResponse.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 15.06.2022.
//

import Foundation

struct CryptoWebSocketResponse: Codable {
    let code: String
    let price: String
    let dailyChangePercentage: String
    let dailyDifferencePrice: String

    enum CodingKeys: String, CodingKey {
        case code = "s"
        case price = "p"
        case dailyChangePercentage = "dc"
        case dailyDifferencePrice = "dd"
    }
}
