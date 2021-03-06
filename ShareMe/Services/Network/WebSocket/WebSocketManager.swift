//
//  WebSocketManager.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 13.06.2022.
//

import Foundation
import UIKit
import SwiftUI

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
    
    private var stockAssets = Set<String>()
    private var cryptoAssets = Set<String>()
    private weak var stockSocketDelegate: URLSessionDelegate?
    private weak var cryptoSocketDelegate: URLSessionDelegate?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appWillEnterForeground() {
        if !stockAssets.isEmpty && stockWebSocket == nil {
            createStockSession(delegate: stockSocketDelegate)
            subscribe(stockSymbols: Array(stockAssets))
        }
        
        if !cryptoAssets.isEmpty && cryptoWebSocket == nil {
            createCryptoSession(delegate: cryptoSocketDelegate)
            subscribe(cryptoSymbols: Array(cryptoAssets))
        }
    }
    
    @objc private func appDidEnterBackgroundNotification() {
        print("appDidEnterBackgroundNotification")
        close()
    }
    
    func createStockSession(delegate: URLSessionDelegate?) {
        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )
        
        guard let url = URL(string: "\(WebSocketManager.hostUrl)\(WebSocketEndpoints.getQuoteRealTimeData.query)") else { return }
        print(url)
        stockWebSocket = session.webSocketTask(with: url)
        stockWebSocket?.resume()
        stockSocketDelegate = delegate
    }
    
    func createCryptoSession(delegate: URLSessionDelegate?) {
        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )
        
        guard let url = URL(string: "\(WebSocketManager.hostUrl)\(WebSocketEndpoints.getCryptoRealTimeData.query)") else { return }
        print(url)
        cryptoWebSocket = session.webSocketTask(with: url)
        cryptoWebSocket?.resume()
        cryptoSocketDelegate = delegate
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
        stockSymbols.forEach { stockAssets.insert($0) }
        let stockMessage = stockSymbols.joined(separator: ", ")
        print(stockMessage)
        send(message: stockMessage, action: .subscribe, webSocket: stockWebSocket)
    }
    
    func subscribe(cryptoSymbols: [String]) {
        cryptoSymbols.forEach { cryptoAssets.insert($0) }
        let cryptoMessage = cryptoSymbols.joined(separator: ", ")
        print(cryptoMessage)
        send(message: cryptoMessage, action: .subscribe, webSocket: cryptoWebSocket)
    }
    
    func unsubscribe(stockSymbols: [String]) {
        stockSymbols.forEach { stockAssets.remove($0) }
        let message = stockSymbols.joined(separator: ", ")
        send(message: message, action: .unsubscribe, webSocket: stockWebSocket)
    }
    
    func unsubscribe(cryptoSymbols: [String]) {
        cryptoSymbols.forEach { cryptoAssets.remove($0) }
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
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
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
    
}
