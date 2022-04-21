//
//  SymbolNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.04.2022.
//

import Foundation

enum AssetType {
    case stock
    case crypto
    
    var assetType: String {
        switch self {
        case .stock:
            return "stock"
        case .crypto:
            return "crypto"
        }
    }
}

class SearchAssetNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        
        case searchAssetWithName(String, AssetType)

        var query: String {
            switch self {
            case .searchAssetWithName(let name, let type):
                // TODO: - Try using URLComponents to stop using Endpoints.apiKey
                return "/search/\(name)?api_token=\(Endpoints.apiKey)&type=\(type.assetType)"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getAssetsWithName(name: String, type: AssetType, completion: @escaping (Result<[SearchRespond], NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.searchAssetWithName(name, type),
            completion: { (result: Result<[SearchRespond], NetworkError>) in
                switch result {
                case .success(let assets):
                    completion(.success(assets))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
