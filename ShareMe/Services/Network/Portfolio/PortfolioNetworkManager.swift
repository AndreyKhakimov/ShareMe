//
//  PortfolioNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.05.2022.
//

import Foundation

class PortfolioNetworkManager {
    
    private let networkManager = NetworkManager.shared
    private let assetInfoNetworkManager = AssetInfoNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    private let quoteNetworkManager = QuoteNetworkManager()
    
    func getAssets(assets: [Asset], completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        let myGroup = DispatchGroup()
//        var portfolioAssets = [Asset]()
        
        for index in 0..<assets.count {
//            portfolioAssets.append(Asset())
//            portfolioAssets[index].code = assets[index].code
//            portfolioAssets[index].exchange = assets[index].exchange
//            portfolioAssets[index].type = assets[index].type
            
            myGroup.enter()
            assetInfoNetworkManager.getAssetInfo(symbol: assets[index].code) { result in
                switch result {
                case .success(let info):
                    guard let currency = info.currency else { break }
                    guard let name = info.name else { break }
                    guard let logo = info.logo else { break }
                    assets[index].logo = logo
                    assets[index].name = name
                    assets[index].currency = currency
                case .failure:
                    break
                }
                myGroup.leave()
            }
            
            myGroup.enter()
            historicalDataNetworkManager.getHistoricalData(assetName: assets[index].code, exchange: assets[index].exchange, from: Date().getDateForDaysAgo(30) .shortFormatString, to: Date().shortFormatString, period: Period.day.rawValue) { result  in
                switch result {
                case .success(let data):
                    let closePrices = data.map { $0.close }
                    assets[index].chartData = closePrices
                case .failure:
                    break
                }
                myGroup.leave()
            }
            
            myGroup.enter()
            quoteNetworkManager.getQuote(name: assets[index].code, exchange: assets[index].exchange) { result  in
                switch result {
                case .success(let quote):
                    let currentPrice = quote.currentPrice
                    let priceChange = quote.priceChange
                    let priceChangePercent = quote.changePercent
                    assets[index].currentPrice = currentPrice
                    assets[index].priceChange = priceChange
                    assets[index].priceChangePercent = priceChangePercent
                case .failure:
                    break
                }
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            completion(.success(true))
        }
    }
    
}
