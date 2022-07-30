//
//  AssetInfoNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.04.2022.
//

import Foundation

class AssetInfoNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        case getAssetInfo(symbol: String)
        
        var scheme: HTTPScheme {
            switch self {
            case .getAssetInfo:
                return .https
            }
        }
        
        var hostURL: String {
            switch self {
            case .getAssetInfo:
                return "finnhub.io"
            }
        }
        
        var path: String {
            switch self {
            case .getAssetInfo:
                return "/api/v1/stock/profile2"
            }
        }
        
        var parameters: [URLQueryItem] {
            switch self {
            case .getAssetInfo(let symbol):
                let params = [
                    URLQueryItem(name: "token", value: API.FinnHub.apiKey),
                    URLQueryItem(name: "symbol", value: symbol)
                ]
                return params
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .getAssetInfo:
                return .get
            }
        }

    }

    private let networkManager = NetworkManager.shared
    
    func getAssetInfo(symbol: String, completion: @escaping (Result<Logo, NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getAssetInfo(symbol: symbol),
            completion: { (result: Result<Logo, NetworkError>) in
                switch result {
                case .success(let logo):
                    completion(.success(logo))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
