//
//  CoreDataBudgetRepository.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation
import CoreData

final class CoreDataBudgetRepository: BudgetRepository {

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    func fetchBudgets(month: Int16, year: Int16) -> Result<[Budget], CoreDataError> {
        let predicate = NSPredicate(format: "month == %d AND year == %d AND isActive == YES", month, year)
        return coreDataManager.fetch(Budget.self, predicate: predicate)
    }

    func createBudget(amount: Double, month: Int16, year: Int16, category: Category) -> Result<Budget, CoreDataError> {
        let budget = coreDataManager.create(Budget.self)
        budget.id = UUID()
        budget.amount = amount
        budget.month = month
        budget.year = year
        budget.isActive = true
        budget.category = category

        return coreDataManager.saveContext().map { budget }
    }

    func deleteBudget(_ budget: Budget) -> Result<Void, CoreDataError> {
        return coreDataManager.delete(budget)
    }

    func fetchBudgetWithSpending(for category: Category, month: Int16, year: Int16) -> Result<BudgetWithSpending, CoreDataError> {
        let budgetPredicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d", category, month, year)
        let budgetResult = coreDataManager.fetch(Budget.self, predicate: budgetPredicate)

        switch budgetResult {
        case .success(let budgets):
            guard let budget = budgets.first else {
                return .failure(.fetchFailed(NSError(domain: "BudgetRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Budget not found"])))
            }

            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return .failure(.fetchFailed(NSError(domain: "BudgetRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid date"])))
            }

            let transactionPredicate = NSPredicate(
                format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
                category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
            )

            let transactionResult = coreDataManager.fetch(Transaction.self, predicate: transactionPredicate)

            switch transactionResult {
            case .success(let transactions):
                let spent = transactions.reduce(0) { $0 + $1.amount }
                return .success(BudgetWithSpending(budget: budget, spent: spent))
            case .failure(let error):
                return .failure(error)
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    func fetchAllBudgetsWithSpending(month: Int16, year: Int16) -> Result<[BudgetWithSpending], CoreDataError> {
        let budgetResult = fetchBudgets(month: month, year: year)

        switch budgetResult {
        case .success(let budgets):
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return .failure(.fetchFailed(NSError(domain: "BudgetRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid date"])))
            }

            // Fetch all transactions for the month at once (optimization)
            let transactionPredicate = NSPredicate(
                format: "type == %@ AND date >= %@ AND date <= %@",
                "expense", startOfMonth as NSDate, endOfMonth as NSDate
            )

            let transactionResult = coreDataManager.fetch(Transaction.self, predicate: transactionPredicate)

            switch transactionResult {
            case .success(let transactions):
                // Group by category
                let spendingByCategory = Dictionary(grouping: transactions) { $0.category }
                    .mapValues { $0.reduce(0) { $0 + $1.amount } }

                let budgetsWithSpending = budgets.map { budget in
                    let spent = spendingByCategory[budget.category] ?? 0
                    return BudgetWithSpending(budget: budget, spent: spent)
                }

                return .success(budgetsWithSpending)

            case .failure(let error):
                return .failure(error)
            }

        case .failure(let error):
            return .failure(error)
        }
    }
}
