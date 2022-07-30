//
//  SymbolNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.04.2022.
//

import Foundation

class SearchAssetNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        case searchAssetWithName(name: String, type: AssetType)
        
        var scheme: HTTPScheme {
            switch self {
            case .searchAssetWithName:
                return .https
            }
        }
        
        var hostURL: String {
            switch self {
            case .searchAssetWithName:
                return "eodhistoricaldata.com"
            }
        }
        
        var path: String {
            switch self {
            case .searchAssetWithName(let name, _):
                return "/api/search/\(name)"
            }
        }
        
        var parameters: [URLQueryItem] {
            switch self {
            case .searchAssetWithName(_, let type):
                let params = [
                    URLQueryItem(name: "api_token", value: API.EOD.apiKey),
                    URLQueryItem(name: "limit", value: "10"),
                    URLQueryItem(name: "type", value: type.assetType),
                    URLQueryItem(name: "exchange", value: type.exchange)
                ]
                return params
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .searchAssetWithName:
                return .get
            }
        }

    }
    
    private let networkManager = NetworkManager.shared
    private let assetInfoNetworkManager = AssetInfoNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    
    @discardableResult
    func getAssetsWithName(name: String, type: AssetType, completion: @escaping (Result<[SearchRespond], NetworkError>) -> Void) -> URLSessionDataTask? {
         networkManager.sendRequest(
            endpoint: Endpoints.searchAssetWithName(name: name, type: type),
            completion: { (result: Result<[SearchRespond], NetworkError>) in
                switch result {
                case .success(var assets):
                    print(assets)
                    let myGroup = DispatchGroup()
                    
                    for i in 0..<assets.count {
                        myGroup.enter()
                        self.assetInfoNetworkManager.getAssetInfo(symbol: assets[i].code) { result in
                            switch result {
                            case .success(let logo):
                                guard let logo = logo.logo else { break }
                                guard let url = URL(string: logo) else { break }
                                print("Logourl \(url)")
                                assets[i].logo = url
                            case .failure:
                                break
                            }
                            myGroup.leave()
                        }
                        
                        myGroup.enter()
                        self.historicalDataNetworkManager.getHistoricalData(assetName: assets[i].code, exchange: assets[i].exchange, from: Date().getDateForDaysAgo(30).shortFormatString, to: Date().shortFormatString, period: Period.day.rawValue) { result  in
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
