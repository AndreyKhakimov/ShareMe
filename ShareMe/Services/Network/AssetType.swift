//
//  AssetType.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.04.2022.
//

import Foundation

@objc
public enum AssetType: Int16, CaseIterable {
    case stock
    case crypto
    
    var assetType: String {
        switch self {
        case .stock:
            return "stock"
        case .crypto:
            return "crypto"
        }
    }
    
    var assetName: String {
        switch self {
        case .stock:
            return "Stocks"
        case .crypto:
            return "Crypto Currencies"
        }
    }
    
    var exchange: String {
        switch self {
        case .stock:
            return "US"
        case .crypto:
            return "CC"
        }
    }
}
