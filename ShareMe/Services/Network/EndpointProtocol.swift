//
//  EndpointProtocol.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 17.03.2022.
//

import Foundation

enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}

enum HTTPScheme: String {
    case http
    case https
}

protocol EndpointProtocol {
    
    var scheme: HTTPScheme { get }
    var hostURL: String { get }
    var path: String { get }
    var parameters: [URLQueryItem] { get }
    var httpMethod: HTTPMethod { get }
}

// TODO: - check query.addingPercentEncoding

//extension EndpointProtocol {
//
//    var scheme: HTTPScheme { return .https }
//    var hostURL: String { "eodhistoricaldata.com" }
////    var url: URL? {
////        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
////        return URL(string: hostURL + encodedQuery)
////    }
//    var httpMethod: HTTPMethod { .get }
//}
