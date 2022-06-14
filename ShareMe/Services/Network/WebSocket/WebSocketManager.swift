//
//  WebSocketManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 13.06.2022.
//

import Foundation

class WebSocketManager {
    
    enum Action: String {
        case subscribe
        case unsubscribe
    }
    
    enum WebSocketEndpoints: WebSocketEndpointProtocol {
        case getQuoteRealTimeData
        case getCryptoRealTimeData
        case getForexRealTimeData
        
        
        var query: String {
            switch self {
            case .getQuoteRealTimeData:
                return "/us-quote?api_token=\(WebSocketEndpoints.apiKey)"
            case .getCryptoRealTimeData:
                return "/us-quote?api_token=\(WebSocketEndpoints.apiKey)"
            case .getForexRealTimeData:
                return "/us-quote?api_token=\(WebSocketEndpoints.apiKey)"
            }
        }
    }
    
    static let hostUrl = "wss://ws.eodhistoricaldata.com/ws"
    
    private var webSocket: URLSessionWebSocketTask?
    
    static let shared = WebSocketManager()
    
    private init() {}
    
    func createSession(delegate: URLSessionDelegate, url: WebSocketEndpoints) {
        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: OperationQueue()
        )
        
        let query = url.query
        guard let url = URL(string: "\(WebSocketManager.hostUrl)\(query)") else { return }
        print(url)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
    }
    
    func ping() {
        webSocket?.sendPing { error in
            guard let error = error  else { return }
            print("Ping error: \(error)")
        }
    }
    
    func close() {
        webSocket?.cancel(with: .goingAway, reason: nil)
    }
    
    func send(message: String, action: Action) {
        self.webSocket?.send(.string("{\"action\": \"\(action.rawValue)\", \"symbols\": \"\(message)\"}"), completionHandler: { error in
            guard let error = error  else { return }
            print("Send error: \(error)")
        })
    }
    
    func subscribe(assetSymbols: [String]) {
        let message = assetSymbols.joined(separator: ", ")
        print(message)
        send(message: message, action: .subscribe)
    }
    
    func unsubscribe(assetSymbols: [String]) {
        let message = assetSymbols.joined(separator: ", ")
        send(message: message, action: .unsubscribe)
    }
    
    func receive() {
        webSocket?.receive(completionHandler: { [ weak self ]result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Data: \(data)")
                case .string(let message):
                    print("Got string: \(message)")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Received error: \(error)")
            }
            self?.receive()
        })
    }
    
}
