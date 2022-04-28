//
//  HistoricalDataNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 26.04.2022.
//

import Foundation

class HistoricalDataNetworkManager {
    
    private enum Endpoints: EndpointProtocol {

        case getHistoricalData(String, String, String, String, String)

        var query: String {
            switch self {
            case .getHistoricalData(let assetName, let exchange, let from, let to, let period):
                return
                "/eod/\(assetName).\(exchange)?fmt=json&from=\(from)&to=\(to)&period=\(period)&api_token=\(Endpoints.apiKey)"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getHistoricalData(assetName: String, exchange: String, from: String, to: String, period: Period, completion: @escaping (Result<[HistoricalDataRespond], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getHistoricalData(assetName, exchange, from, to, period.rawValue),
            completion: { (result: Result<[HistoricalDataRespond], NetworkError>) in
                switch result {
                case .success(let historicalData):
                    completion(.success(historicalData))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
