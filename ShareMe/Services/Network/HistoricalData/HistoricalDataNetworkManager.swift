//
//  HistoricalDataNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 26.04.2022.
//

import Foundation

class HistoricalDataNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        case getHistoricalData(assetName: String, exchange: String, from: String, to: String, period: String)
        case getIntradayHistoricalData(assetName: String, exchange: String, from: String, to: String, interval: String)
        case getNewsForAsset(assetName: String, exchange: String)
        
        var scheme: HTTPScheme {
            switch self {
            case .getHistoricalData:
                return .https
            case .getIntradayHistoricalData:
                return .https
            case .getNewsForAsset:
                return .https
            }
        }
        
        var hostURL: String { "eodhistoricaldata.com" }
        
        var path: String {
            switch self {
            case .getHistoricalData(assetName: let assetName, exchange: let exchange, _, _, _):
                return "/api/eod/\(assetName).\(exchange)"
            case .getIntradayHistoricalData(assetName: let assetName, exchange: let exchange, _, _, _):
                return "/api/intraday/\(assetName).\(exchange)"
            case .getNewsForAsset:
                return "/api/news/"
            }
        }
        
        var parameters: [URLQueryItem] {
            switch self {
            case .getHistoricalData(_, _, from: let from, to: let to, period: let period):
                let params = [
                    URLQueryItem(name: "api_token", value: API.EOD.apiKey),
                    URLQueryItem(name: "fmt", value: "json"),
                    URLQueryItem(name: "from", value: from),
                    URLQueryItem(name: "to", value: to),
                    URLQueryItem(name: "period", value: period)
                ]
                return params
            case .getIntradayHistoricalData(_, _, from: let from, to: let to, interval: let interval):
                let params = [
                    URLQueryItem(name: "api_token", value: API.EOD.apiKey),
                    URLQueryItem(name: "fmt", value: "json"),
                    URLQueryItem(name: "from", value: from),
                    URLQueryItem(name: "to", value: to),
                    URLQueryItem(name: "interval", value: interval)
                ]
                return params
            case .getNewsForAsset(assetName: let assetName, exchange: let exchange):
                let params = [
                    URLQueryItem(name: "api_token", value: API.EOD.apiKey),
                    URLQueryItem(name: "s", value: "\(assetName).\(exchange)"),
                    URLQueryItem(name: "limit", value: "10")
                ]
                return params
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .getHistoricalData:
                return .get
            case .getIntradayHistoricalData:
                return .get
            case .getNewsForAsset:
                return .get
            }
        }

    }
    
    private let networkManager = NetworkManager.shared
    
    func getHistoricalData(assetName: String, exchange: String, from: String, to: String, period: String, completion: @escaping (Result<[HistoricalDataRespond], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getHistoricalData(assetName: assetName, exchange: exchange, from: from, to: to, period: period),
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
            endpoint: Endpoints.getIntradayHistoricalData(assetName: assetName, exchange: exchange, from: String(from), to: String(to), interval: interval),
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
            endpoint: Endpoints.getNewsForAsset(assetName: assetName, exchange: exchange),
            completion: { (result: Result<[NewsResponse], NetworkError>) in
                switch result {
                case .success(var news):
                    let formatter = ISO8601DateFormatter()
                    let df = DateFormatter()
                    df.dateFormat = "HH:mm MMM dd"
                    // 18:01 Aug 16
                    for index in 0..<news.count {
                        let date = formatter.date(from: news[index].date) ?? Date()
                        let formattedString = df.string(from: date)
                        news[index].date = formattedString
                    }
                    completion(.success(news))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
