//
//  NetworkManager.swift
//  ContactsList
//
//  Created by Andrey Khakimov on 06.12.2021.
//

import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    
    static let hostUrl = "https://eodhistoricaldata.com/api"
    
    private init() {}
    
    func sendRequest<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (Result<Response, NetworkError>) -> Void) {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.httpMethod
        print(request.url)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(.other(error)))
                return
            }
            
            var data = data
            if Response.self == Void.self {
                data = Data()
            }
            guard let data = data
            else {
                completion(.failure(.noData))
                return
            }
            do {
                let result = try JSONDecoder().decode(Response.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
}


