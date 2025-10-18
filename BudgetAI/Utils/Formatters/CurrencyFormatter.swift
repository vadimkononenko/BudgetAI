//
//  CurrencyFormatter.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation

final class CurrencyFormatter {

    static let shared = CurrencyFormatter()

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = "."
        return formatter
    }()

    private init() {}

    func format(_ amount: Double) -> String {
        guard let formattedNumber = numberFormatter.string(from: NSNumber(value: amount)) else {
            return "0.00 ₴"
        }
        return "\(formattedNumber) ₴"
    }

    func formatWithoutSymbol(_ amount: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }

    func parse(_ string: String) -> Double? {
        // Remove currency symbol and spaces
        let cleanedString = string.replacingOccurrences(of: "₴", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanedString)
    }
}
