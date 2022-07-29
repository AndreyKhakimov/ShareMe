//
//  WebSocketEndpointProtocol.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 14.06.2022.
//

import Foundation

protocol WebSocketEndpointProtocol {
    static var hostURL: String { get }
    static var apiKey: String { get }
    
    var query: String { get }
    var url: URL? { get }
}

extension WebSocketEndpointProtocol {
    static var hostURL: String { WebSocketManager.hostUrl }
    static var apiKey: String { API.EOD.apiKey }
    var url: URL? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: Self.hostURL + encodedQuery)
    }
}
