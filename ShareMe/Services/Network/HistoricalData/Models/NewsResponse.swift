//
//  NewsResponse.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 18.06.2022.
//

import Foundation

struct NewsResponse: Codable {
    var date: String
    let title: String
    let content: String
    let link: String
}

