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
        print(request.url)
        request.httpMethod = endpoint.httpMethod
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
                print("TRYING TO DECODE DATA:")
                if let data = data {
                    do {
                        let decodedObject = try JSONDecoder().decode(Response.self, from: data)
                        print("DECODED \(Response.self) SUCCESSFULLY")
                        print(decodedObject)
                        DispatchQueue.main.async {
                            completion(.success(decodedObject))
                        }
                    } catch let DecodingError.dataCorrupted(context) {
                        print(context)
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch let DecodingError.typeMismatch(type, context)  {
                        print("Type '\(type)' mismatch:", context.debugDescription)
                        print("codingPath:", context.codingPath)
                    } catch {
                        print("error: ", error)
                    }
                }
            } else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        }.resume()
    }
    
}


