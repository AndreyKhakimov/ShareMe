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
        case getIntradayHistoricalData(String, String, String, String, String)
        case getNewsForAsset(String, String)

        var query: String {
            switch self {
            case .getHistoricalData(let assetName, let exchange, let from, let to, let period):
                return "/eod/\(assetName).\(exchange)?fmt=json&from=\(from)&to=\(to)&period=\(period)&api_token=\(Endpoints.apiKey)"
            case .getIntradayHistoricalData(let assetName, let exchange, let from, let to, let interval):
                return "/intraday/\(assetName).\(exchange)?fmt=json&from=\(from)&to=\(to)&interval=\(interval)&api_token=\(Endpoints.apiKey)"
            case .getNewsForAsset(let assetName, let exchange):
                return "/news/?api_token=\(Endpoints.apiKey)&s=\(assetName).\(exchange)&limit=10"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getHistoricalData(assetName: String, exchange: String, from: String, to: String, period: String, completion: @escaping (Result<[HistoricalDataRespond], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getHistoricalData(assetName, exchange, from, to, period),
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
    
    func getIntradayHistoricalData(assetName: String, exchange: String, from: Double, to: Double, interval: String, completion: @escaping (Result<[HistoricalIntradayDataResponse], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getIntradayHistoricalData(assetName, exchange, String(from), String(to), interval),
            completion: { (result: Result<[HistoricalIntradayDataResponse], NetworkError>) in
                switch result {
                case .success(let historicalData):
                    completion(.success(historicalData))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
    func getNewsForAsset(assetName: String, exchange: String, completion: @escaping (Result<[NewsResponse], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getNewsForAsset(assetName, exchange),
            completion: { (result: Result<[NewsResponse], NetworkError>) in
                switch result {
                case .success(let news):
                    completion(.success(news))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
