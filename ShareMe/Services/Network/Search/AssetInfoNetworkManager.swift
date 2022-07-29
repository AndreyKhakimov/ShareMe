//
//  AssetInfoNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.04.2022.
//

import Foundation

class AssetInfoNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        
        case getAssetInfo(String)
        
        static var hostURL = "https://finnhub.io/api/v1"

        var query: String {
            switch self {
            case .getAssetInfo(let symbol):
                return "/stock/profile2?symbol=\(symbol)&token=\(API.FinnHub.apiKey)"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getAssetInfo(symbol: String, completion: @escaping (Result<Logo, NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getAssetInfo(symbol),
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
