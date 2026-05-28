//
//  CalendarManager.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import Foundation

class CalendarManager {

    static let shared = CalendarManager()

    let calendar = Calendar.current

    // MONTH TITLE

    func monthYearString(from date: Date) -> String {

        let formatter = DateFormatter()

        formatter.dateFormat = "MMMM yyyy"

        return formatter.string(from: date)
    }

    // DAYS IN MONTH

    func daysInMonth(from date: Date) -> [Date] {

        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: date
        ) else {
            return []
        }

        let components = calendar.dateComponents(
            [.year, .month],
            from: date
        )

        guard let firstDay = calendar.date(from: components) else {
            return []
        }

        return range.compactMap {

            calendar.date(
                byAdding: .day,
                value: $0 - 1,
                to: firstDay
            )
        }
    }
}
