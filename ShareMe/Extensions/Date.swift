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
    
    func getPreviousMonthDate() -> Date {
        Calendar.current.date(byAdding: .month, value: -1, to: self) ?? self
    }
    
    func getPreviousWeekDate() -> Date {
        Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: self) ?? self
    }

}
