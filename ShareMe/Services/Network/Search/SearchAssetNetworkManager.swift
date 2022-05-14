//
//  SymbolNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.04.2022.
//

import Foundation

class SearchAssetNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        case searchAssetWithName(String, AssetType)
        
        var query: String {
            switch self {
            case .searchAssetWithName(let name, let type):
                // TODO: - Try using URLComponents to stop using Endpoints.apiKey
                return "/search/\(name)?api_token=\(Endpoints.apiKey)&limit=3&type=\(type.rawValue)"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    private let assetInfoNetworkManager = AssetInfoNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    
    func getAssetsWithName(name: String, type: AssetType, completion: @escaping (Result<[SearchRespond], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.searchAssetWithName(name, type),
            completion: { (result: Result<[SearchRespond], NetworkError>) in
                switch result {
                case .success(var assets):
                    let myGroup = DispatchGroup()
                    
                    for i in 0..<assets.count {
                        myGroup.enter()
                        self.assetInfoNetworkManager.getAssetInfo(symbol: assets[i].code) { result in
                            switch result {
                            case .success(let logo):
                                guard let logo = logo.logo else { break }
                                guard let url = URL(string: logo) else { break }
                                assets[i].logo = url
                            case .failure:
                                break
                            }
                            myGroup.leave()
                        }
                        
                        myGroup.enter()
                        self.historicalDataNetworkManager.getHistoricalData(assetName: assets[i].code, exchange: assets[i].exchange, from: Date().getPreviousMonthDate().shortFormatString, to: Date().shortFormatString, period: .day) { result  in
                            switch result {
                            case .success(let data):
                                let closePrices = data.map { $0.close }
                                assets[i].chartData = closePrices
                            case .failure:
                                break
                            }
                            myGroup.leave()
                        }
                    }

                    myGroup.notify(queue: .main) {
                        completion(.success(assets))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
