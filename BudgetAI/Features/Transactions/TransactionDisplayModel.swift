//
//  TransactionDisplayModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

struct TransactionDisplayModel: Hashable {
    let id: UUID
    let categoryName: String
    let categoryIcon: String
    let categoryColor: UIColor
    let amount: String
    let amountRaw: Double
    let type: String
    let typeColor: UIColor
    let date: String
    let dateRaw: Date
    let description: String?
    let timeAgo: String

    init(transaction: Transaction) {
        self.id = transaction.id ?? UUID()
        self.categoryName = transaction.category?.name ?? ""
        self.categoryIcon = transaction.category?.icon ?? ""
        self.categoryColor = UIColor(hex: transaction.category?.colorHex ?? "#000000") ?? .white

        self.amountRaw = transaction.amount
        self.amount = CurrencyFormatter.shared.format(transaction.amount)

        self.type = transaction.type ?? "expense"
        self.typeColor = (transaction.type == "income") ? .systemGreen : .systemRed

        self.dateRaw = transaction.date ?? Date()
        self.date = DateFormatter.shortDate.string(from: transaction.date ?? Date())
        self.timeAgo = Self.timeAgoSinceDate(transaction.date ?? Date())

        self.description = transaction.transactionDescription
    }

    private static func timeAgoSinceDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)

        if let years = components.year, years > 0 {
            return "\(years) \(years == 1 ? "рік" : "років") тому"
        }
        if let months = components.month, months > 0 {
            return "\(months) \(months == 1 ? "місяць" : "місяців") тому"
        }
        if let days = components.day, days > 0 {
            if days == 1 {
                return "вчора"
            }
            return "\(days) \(days == 1 ? "день" : "днів") тому"
        }
        if let hours = components.hour, hours > 0 {
            return "\(hours) \(hours == 1 ? "годину" : "годин") тому"
        }
        if let minutes = components.minute, minutes > 0 {
            return "\(minutes) \(minutes == 1 ? "хвилину" : "хвилин") тому"
        }

        return "щойно"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TransactionDisplayModel, rhs: TransactionDisplayModel) -> Bool {
        return lhs.id == rhs.id
    }
}
