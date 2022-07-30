//
//  NetworkManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 06.12.2021.
//

import Foundation

final class NetworkManager {
    
    static let shared = NetworkManager()
        
    private init() {}
    
    private func buildURL(endpoint: EndpointProtocol) -> URLComponents {
        var components = URLComponents()
        components.scheme = endpoint.scheme.rawValue
        components.host = endpoint.hostURL
        components.path = endpoint.path
        components.queryItems = endpoint.parameters
        return components
    }
    
    @discardableResult
    func sendRequest<Response: Decodable>(endpoint: EndpointProtocol, completion: @escaping (Result<Response, NetworkError>) -> Void) -> URLSessionDataTask? {
        let components = buildURL(endpoint: endpoint)
        guard let url = components.url else {
            completion(.failure(.badURL))
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod.rawValue
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                if let rawURLError = error as? URLError,
                    rawURLError.code == URLError.Code.cancelled {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.other(error)))
                }
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
        }
        task.resume()
        return task
    }
    
}


