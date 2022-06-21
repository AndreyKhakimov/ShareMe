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
                return "/crypto?api_token=\(WebSocketEndpoints.apiKey)"
            case .getForexRealTimeData:
                return "/forex?api_token=\(WebSocketEndpoints.apiKey)"
            }
        }
    }
    
    static let hostUrl = "wss://ws.eodhistoricaldata.com/ws"
    
    var stockWebSocket: URLSessionWebSocketTask?
    var cryptoWebSocket: URLSessionWebSocketTask?
    
    func createStockSession(delegate: URLSessionDelegate) {
        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: OperationQueue()
        )
        
        guard let url = URL(string: "\(WebSocketManager.hostUrl)\(WebSocketEndpoints.getQuoteRealTimeData.query)") else { return }
        print(url)
        stockWebSocket = session.webSocketTask(with: url)
        stockWebSocket?.resume()
    }
    
    func createCryptoSession(delegate: URLSessionDelegate) {
        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: OperationQueue()
        )
        
        guard let url = URL(string: "\(WebSocketManager.hostUrl)\(WebSocketEndpoints.getCryptoRealTimeData.query)") else { return }
        print(url)
        cryptoWebSocket = session.webSocketTask(with: url)
        cryptoWebSocket?.resume()
    }
    
    func ping() {
        stockWebSocket?.sendPing { error in
            guard let error = error  else { return }
            print("Ping error: \(error)")
        }
        cryptoWebSocket?.sendPing { error in
            guard let error = error  else { return }
            print("Ping error: \(error)")
        }
    }
    
    func close() {
        stockWebSocket?.cancel(with: .goingAway, reason: nil)
        cryptoWebSocket?.cancel(with: .goingAway, reason: nil)
    }
    
    func send(message: String, action: Action, webSocket: URLSessionWebSocketTask?) {
        guard let webSocket = webSocket else { return }
        webSocket.send(.string("{\"action\": \"\(action.rawValue)\", \"symbols\": \"\(message)\"}"), completionHandler: { error in
            guard let error = error  else { return }
            print("Send error: \(error)")
        })
    }
    
    func subscribe(stockSymbols: [String]) {
        let stockMessage = stockSymbols.joined(separator: ", ")
        print(stockMessage)
        send(message: stockMessage, action: .subscribe, webSocket: stockWebSocket)
    }
    
    func subscribe(cryptoSymbols: [String]) {
        let cryptoMessage = cryptoSymbols.joined(separator: ", ")
        print(cryptoMessage)
        send(message: cryptoMessage, action: .subscribe, webSocket: cryptoWebSocket)
    }
    
    func unsubscribe(stockSymbols: [String]) {
        let message = stockSymbols.joined(separator: ", ")
        send(message: message, action: .unsubscribe, webSocket: stockWebSocket)
    }
    
    func unsubscribe(cryptoSymbols: [String]) {
        let message = cryptoSymbols.joined(separator: ", ")
        send(message: message, action: .unsubscribe, webSocket: cryptoWebSocket)
    }
    
    func stockReceive(stockCompletion: @escaping (QuoteWebSocketResponse) -> Void) {
        stockWebSocket?.receive(completionHandler: { [ weak self ] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.onReceiveStockData(
                        data,
                        stockCompletion: stockCompletion
                    )
                    print("Data: \(data)")
                case .string(let message):
                    if let data = message.data(using: .utf8) {
                        self.onReceiveStockData(
                            data,
                            stockCompletion: stockCompletion
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
                self.stockReceive(
                    stockCompletion: stockCompletion
                )
            }
        })
        
    }
    
    func cryptoReceive(cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void) {
        cryptoWebSocket?.receive(completionHandler: { [ weak self ] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.onReceiveCryptoData(
                        data,
                        cryptoCompletion: cryptoCompletion
                    )
                    print("Data: \(data)")
                case .string(let message):
                    if let data = message.data(using: .utf8) {
                        self.onReceiveCryptoData(
                            data,
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
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.cryptoReceive(
                    cryptoCompletion: cryptoCompletion
                )
            }
        })
        
    }
    
    private func onReceiveStockData(
        _ data: Data,
        stockCompletion: @escaping (QuoteWebSocketResponse) -> Void)
    {
        let decoder = JSONDecoder()
        if let socketData = try? decoder.decode(QuoteWebSocketResponse.self, from: data) {
            stockCompletion(socketData)
        }
    }
    
    private func onReceiveCryptoData(
        _ data: Data,
        cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void)
    {
        let decoder = JSONDecoder()
        if let socketData = try? decoder.decode(CryptoWebSocketResponse.self, from: data) {
            cryptoCompletion(socketData)
        }
    }
    
//    func receive(
//        stockCompletion: @escaping (QuoteWebSocketResponse) -> Void,
//        cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void)
//    {
//        stockWebSocket?.receive(completionHandler: { [ weak self ] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let message):
//                switch message {
//                case .data(let data):
//                    self.onReceiveData(
//                        data,
//                        stockCompletion: stockCompletion,
//                        cryptoCompletion: cryptoCompletion
//                    )
//                    print("Data: \(data)")
//                case .string(let message):
//                    if let data = message.data(using: .utf8) {
//                        self.onReceiveData(
//                            data,
//                            stockCompletion: stockCompletion,
//                            cryptoCompletion: cryptoCompletion
//                        )
//                    }
//                    print("Got string: \(message)")
//                @unknown default:
//                    break
//                }
//            case .failure(let error):
//                print("Failed to receive message: \(error.localizedDescription)")
//            }
//            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
//                self.receive(
//                    stockCompletion: stockCompletion,
//                    cryptoCompletion: cryptoCompletion
//                )
//            }
//        })
//
//    }
//
//    private func onReceiveData(
//        _ data: Data,
//        stockCompletion: @escaping (QuoteWebSocketResponse) -> Void,
//        cryptoCompletion: @escaping (CryptoWebSocketResponse) -> Void)
//    {
//        let decoder = JSONDecoder()
//        if let socketData = try? decoder.decode(QuoteWebSocketResponse.self, from: data) {
//            stockCompletion(socketData)
//        } else if let socketData = try? decoder.decode(CryptoWebSocketResponse.self, from: data) {
//            cryptoCompletion(socketData)
//        }
//    }
    
}
