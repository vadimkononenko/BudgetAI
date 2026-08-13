//
//  BudgetDisplayModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

struct BudgetDisplayModel: Hashable {
    let id: UUID
    let categoryName: String
    let categoryIcon: String
    let categoryColor: UIColor
    let budgetAmount: String
    let budgetAmountRaw: Double
    let spentAmount: String
    let spentAmountRaw: Double
    let remainingAmount: String
    let remainingAmountRaw: Double
    let progressPercentage: Double
    let progressColor: UIColor
    let isOverBudget: Bool

    init(budgetWithSpending: BudgetWithSpending) {
        let budget = budgetWithSpending.budget
        let spent = budgetWithSpending.spent
        let remaining = budgetWithSpending.remaining
        let progress = budgetWithSpending.progressPercentage

        self.id = budget.id ?? UUID()
        self.categoryName = budget.category?.name ?? ""
        self.categoryIcon = budget.category?.icon ?? ""
        self.categoryColor = UIColor(hex: budget.category?.colorHex ?? "#000000") ?? .white

        self.budgetAmountRaw = budget.amount
        self.budgetAmount = CurrencyFormatter.shared.format(budget.amount)

        self.spentAmountRaw = spent
        self.spentAmount = CurrencyFormatter.shared.format(spent)

        self.remainingAmountRaw = remaining
        self.remainingAmount = CurrencyFormatter.shared.format(remaining)

        self.progressPercentage = progress
        self.isOverBudget = spent > budget.amount

        if isOverBudget {
            self.progressColor = .systemRed
        } else if progress > 0.8 {
            self.progressColor = .systemOrange
        } else {
            self.progressColor = .systemGreen
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BudgetDisplayModel, rhs: BudgetDisplayModel) -> Bool {
        return lhs.id == rhs.id
    }
}
