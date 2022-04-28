//
//  Date.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 27.04.2022.
//

import Foundation

extension Date {
    
    var getCurrentDate: String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: date)
        return dateString
    }
    
}
