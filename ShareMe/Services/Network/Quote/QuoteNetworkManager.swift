//
//  QuoteNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import Foundation

class QuoteNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        case getQuote(assetName: String, exchange: String)
        
        var scheme: HTTPScheme {
            switch self {
            case .getQuote:
                return .https
            }
        }
        
        var hostURL: String {
            switch self {
            case .getQuote:
                return "eodhistoricaldata.com"
            }
        }
        
        var path: String {
            switch self {
            case .getQuote(let assetName, let exchange):
                return "/api/real-time/\(assetName).\(exchange)"
            }
        }
        
        var parameters: [URLQueryItem] {
            switch self {
            case .getQuote:
                let params = [
                    URLQueryItem(name: "api_token", value: API.EOD.apiKey),
                    URLQueryItem(name: "fmt", value: "json")
                ]
                return params
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .getQuote:
                return .get
            }
        }

    }
    
    private let networkManager = NetworkManager.shared
    
    func getQuote(name: String, exchange: String, completion: @escaping (Result<Quote, NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getQuote(assetName: name, exchange: exchange),
            completion: { (result: Result<Quote, NetworkError>) in
                switch result {
                case .success(let asset):
                    completion(.success(asset))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}

