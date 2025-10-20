//
//  CategoryStatDisplayModel.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import UIKit

struct CategoryStatDisplayModel: Hashable {
    let category: Category
    let categoryName: String
    let categoryIcon: String
    let categoryColor: UIColor
    let amount: String
    let amountRaw: Double
    let percentage: Double
    let percentageText: String

    init(category: Category, amount: Double, totalExpenses: Double) {
        self.category = category
        self.categoryName = category.name ?? ""
        self.categoryIcon = category.icon ?? ""
        self.categoryColor = UIColor(hex: category.colorHex ?? "#000000") ?? .white

        self.amountRaw = amount
        self.amount = CurrencyFormatter.shared.format(amount)

        self.percentage = totalExpenses > 0 ? (amount / totalExpenses) : 0
        self.percentageText = String(format: "%.1f%%", self.percentage * 100)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(categoryName)
        hasher.combine(amountRaw)
    }

    static func == (lhs: CategoryStatDisplayModel, rhs: CategoryStatDisplayModel) -> Bool {
        return lhs.categoryName == rhs.categoryName && lhs.amountRaw == rhs.amountRaw
    }
}
