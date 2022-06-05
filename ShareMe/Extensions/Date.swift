//
//  Date.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 27.04.2022.
//

import Foundation

extension Date {

    var shortFormatString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateString = df.string(from: self)
        return dateString
    }
    
    func getDateForDaysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}
