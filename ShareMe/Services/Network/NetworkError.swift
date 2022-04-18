//
//  NetworkError.swift
//  ContactsList
//
//  Created by Andrey Khakimov on 20.12.2021.
//

import Foundation

enum NetworkError: Error {
    case noData
    case decodingError
    case other(Error)
    
    var title: String {
        "Error"
    }
    
    var description: String {
        switch self {
        case .noData:
            return "The data received from the server is invalid"
            
        case .decodingError:
            return "The data can not be decoded"
            
        case .other(let error):
            return error.localizedDescription
        }
    }
}
