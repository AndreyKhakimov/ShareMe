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
    
    func getPreviousWeekDate() -> Date {
        Calendar.current.date(byAdding: .weekOfMonth, value: -1, to: self) ?? self
    }
    
    func getPreviousMonthDate() -> Date {
        Calendar.current.date(byAdding: .month, value: -1, to: self) ?? self
    }
    
    func getHalfYearAgoDate() -> Date {
        Calendar.current.date(byAdding: .month, value: -6, to: self) ?? self
    }
    
    func getYearAgoDate() -> Date {
        Calendar.current.date(byAdding: .year, value: -1, to: self) ?? self
    }
    
    func getTwoYearsAgoDate() -> Date {
        Calendar.current.date(byAdding: .year, value: -5, to: self) ?? self
    }
    
}
