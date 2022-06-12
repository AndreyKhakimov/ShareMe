//
//  EndpointProtocol.swift
//  ContactsList
//
//  Created by Andrey Khakimov on 17.03.2022.
//

import Foundation

protocol EndpointProtocol {
    static var hostURL: String { get }
    static var apiKey: String { get }
    
    var query: String { get }
    var url: URL? { get }
    var httpMethod: String { get }
}

extension EndpointProtocol {
    static var hostURL: String { NetworkManager.hostUrl }
    static var apiKey: String { API.apiKey }
    var url: URL? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: Self.hostURL + encodedQuery)
    }
    var httpMethod: String { "GET" }
}
