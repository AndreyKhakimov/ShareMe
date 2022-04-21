//
//  QuoteNetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

class QuoteNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        
        case getQuote(String, String)

        var query: String {
            switch self {
            case .getQuote(let assetName, let exchange):
                return "/real-time/\(assetName).\(exchange)?api_token=\(Endpoints.apiKey)&fmt=json"
                //real-time/BTC-USD.CC?api_token=OeAFFmMliFG5orCUuwAKQ8l4WWFQ67YX&fmt=json
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getQuote(name: String, exchange: String, completion: @escaping (Result<Quote, NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getQuote(name, exchange),
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

