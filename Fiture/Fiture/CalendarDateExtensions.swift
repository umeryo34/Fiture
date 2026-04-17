//
//  CalendarDateExtensions.swift
//  Fiture
//

import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }
}
