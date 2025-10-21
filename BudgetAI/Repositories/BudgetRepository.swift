//
//  BudgetRepository.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

// MARK: - Budget Repository Protocol

protocol BudgetRepository {
    func fetchBudgets(month: Int16, year: Int16) -> Result<[Budget], CoreDataError>
    func createBudget(amount: Double, month: Int16, year: Int16, category: Category) -> Result<Budget, CoreDataError>
    func deleteBudget(_ budget: Budget) -> Result<Void, CoreDataError>
    func fetchBudgetWithSpending(for category: Category, month: Int16, year: Int16) -> Result<BudgetWithSpending, CoreDataError>
    func fetchAllBudgetsWithSpending(month: Int16, year: Int16) -> Result<[BudgetWithSpending], CoreDataError>
}

// MARK: - Budget With Spending Model

struct BudgetWithSpending {
    let budget: Budget
    let spent: Double
    let remaining: Double
    let progressPercentage: Double

    init(budget: Budget, spent: Double) {
        self.budget = budget
        self.spent = spent
        self.remaining = budget.amount - spent
        self.progressPercentage = budget.amount > 0 ? min(spent / budget.amount, 1.0) : 0
    }
}
