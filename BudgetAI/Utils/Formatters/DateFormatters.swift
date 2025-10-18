//
//  DateFormatters.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation

extension DateFormatter {

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
}

extension Date {

    func startOfMonth() -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }

    func endOfMonth() -> Date? {
        guard let startOfMonth = startOfMonth() else { return nil }
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
    }

    func startOfYear() -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)
    }
}
