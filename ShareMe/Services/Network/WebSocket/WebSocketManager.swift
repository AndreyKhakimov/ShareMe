//
//  WebSocketManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 13.06.2022.
//

import Foundation

class WebSocketManager {
    
    let webSocketType: WebSocketEndpoints
    
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
                return "/crypto?api_token=\(WebSocketEndpoints.apiKey)"
            case .getForexRealTimeData:
                return "/forex?api_token=\(WebSocketEndpoints.apiKey)"
            }
        }
    }
    
    static let hostUrl = "wss://ws.eodhistoricaldata.com/ws"
    
    private var webSocket: URLSessionWebSocketTask?
    
    init(webSocketType: WebSocketEndpoints) {
        self.webSocketType = webSocketType
    }
    
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
    
    func receive(
        stockCompletion: @escaping (QuoteWebSocketResponse) -> Void,
        cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void)
    {
        webSocket?.receive(completionHandler: { [ weak self ] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.onReceiveData(
                        data,
                        stockCompletion: stockCompletion,
                        cryptoCompletion: cryptoCompletion
                    )
                    print("Data: \(data)")
                case .string(let message):
                    if let data = message.data(using: .utf8) {
                        self.onReceiveData(
                            data,
                            stockCompletion: stockCompletion,
                            cryptoCompletion: cryptoCompletion
                        )
                    }
                    print("Got string: \(message)")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Failed to receive message: \(error.localizedDescription)")
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                self.receive(
                    stockCompletion: stockCompletion,
                    cryptoCompletion: cryptoCompletion
                )
            }
        })
    }
    
    private func onReceiveData(
        _ data: Data,
        stockCompletion: @escaping (QuoteWebSocketResponse) -> Void,
        cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void)
    {
        let decoder = JSONDecoder()
        if let socketData = try? decoder.decode(QuoteWebSocketResponse.self, from: data) {
            stockCompletion(socketData)
        } else if let socketData = try? decoder.decode(CryptoWebSocketResponse.self, from: data) {
            cryptoCompletion(socketData)
        }
    }
    
}
