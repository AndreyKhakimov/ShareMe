//
//  QuoteNetworkManager.swift
//  ContactsList
//
//  Created by Andrey Khakimov on 10.04.2022.
//

class PricesNetworkManager {
    
    private enum Endpoints: EndpointProtocol {
        
        case getQuotation(String)
        case getPrices(symbol: String, resolution: String, from: Int, to: Int)
        
        var query: String {
            switch self {
            case .getQuotation(let symbol):
                return "/quote?symbol=\(symbol)&token=\(Endpoints.apiKey)"
            case .getPrices(let symbol, let resolution, let from, let to):
                return  "/stock/candle?symbol=\(symbol)&resolution=\(resolution)&from=\(from)&to=\(to)&token=\(Endpoints.apiKey)"
            }
        }
    }
    
    private let networkManager = NetworkManager.shared
    
    func getCompanyQuote(companySymbol: String, completion: @escaping (Result<Quotation, NetworkError>) -> Void) {
        networkManager.sendRequest(
            endpoint: Endpoints.getQuotation(companySymbol),
            completion: { (result: Result<Quotation, NetworkError>) in
                switch result {
                case .success(let quote):
                    completion(.success(quote))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
}
