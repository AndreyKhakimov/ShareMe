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
    
    func getAssets(assets: [Asset], completion: @escaping (Result<[PortfolioAsset], NetworkError>) -> Void) {
        let myGroup = DispatchGroup()
        var portfolioAssets = [PortfolioAsset]()
        
        for index in 0..<assets.count {
            portfolioAssets.append(PortfolioAsset())
            portfolioAssets[index].code = assets[index].code
            portfolioAssets[index].exchange = assets[index].exchange
            
            myGroup.enter()
            assetInfoNetworkManager.getAssetInfo(symbol: assets[index].code) { result in
                switch result {
                case .success(let logo):
                    guard let logo = logo.logo else { break }
                    guard let url = URL(string: logo) else { break }
                    portfolioAssets[index].logo = url
                case .failure:
                    break
                }
                myGroup.leave()
            }
            
            myGroup.enter()
            historicalDataNetworkManager.getHistoricalData(assetName: assets[index].code, exchange: assets[index].exchange, from: Date().getPreviousMonthDate().shortFormatString, to: Date().shortFormatString, period: .day) { result  in
                switch result {
                case .success(let data):
                    let closePrices = data.map { $0.close }
                    portfolioAssets[index].chartData = closePrices
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
                    portfolioAssets[index].currentPrice = currentPrice
                case .failure:
                    break
                }
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: .main) {
            completion(.success(portfolioAssets))
        }
    }
    
}
