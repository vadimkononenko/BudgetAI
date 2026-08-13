//
//  TransactionDetailViewModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation
import UIKit

final class TransactionDetailViewModel {

    // MARK: - Properties

    private let transaction: Transaction
    private let coreDataManager: CoreDataManager

    // Track changes
    private(set) var hasUnsavedChanges = false
    private var originalAmount: Double = 0
    private var originalDescription: String?

    // Callbacks
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onTransactionDeleted: (() -> Void)?
    var onChangesSaved: (() -> Void)?

    // MARK: - Computed Properties

    var categoryIcon: String {
        transaction.category?.icon ?? "📦"
    }

    var categoryName: String {
        transaction.category?.name ?? "Без категорії"
    }

    var amount: Double {
        transaction.amount
    }

    var amountText: String {
        String(format: "%.2f", transaction.amount)
    }

    var description: String? {
        transaction.transactionDescription
    }

    var date: Date {
        transaction.date ?? Date()
    }

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy, HH:mm"
        dateFormatter.locale = Locale(identifier: "uk_UA")
        return dateFormatter.string(from: date)
    }

    var isExpense: Bool {
        transaction.type == "expense"
    }

    var isIncome: Bool {
        transaction.type == "income"
    }

    var transactionTypeColor: UIColor {
        isExpense ? .systemRed : .systemGreen
    }

    // MARK: - Budget Data

    struct BudgetData {
        let progress: Float
        let remaining: Double
        let progressTintColor: UIColor
        let remainingLabelColor: UIColor
        let remainingText: String
    }

    private(set) var budgetData: BudgetData?

    // MARK: - Income Goal Data

    struct IncomeGoalData {
        let progress: Float
        let achieved: Double
        let progressTintColor: UIColor
        let achievedLabelColor: UIColor
        let achievedText: String
    }

    private(set) var incomeGoalData: IncomeGoalData?

    // MARK: - Category Stats Data

    struct CategoryStatsData {
        let totalAmount: Double
        let transactionsCount: Int
        let totalText: String
        let countText: String
    }

    private(set) var categoryStatsData: CategoryStatsData?

    // MARK: - Initialization

    init(transaction: Transaction, coreDataManager: CoreDataManager = .shared) {
        self.transaction = transaction
        self.coreDataManager = coreDataManager
        self.originalAmount = transaction.amount
        self.originalDescription = transaction.transactionDescription
    }

    // MARK: - Public Methods

    func loadData() {
        if isExpense, let category = transaction.category {
            loadBudgetData(for: category)
        }

        if isIncome, let category = transaction.category {
            loadIncomeGoalData(for: category)
        }

        loadCategoryStats()
        onDataUpdated?()
    }

    func updateAmount(_ newAmount: Double) {
        checkForChanges(amount: newAmount, description: transaction.transactionDescription)
    }

    func updateDescription(_ newDescription: String?) {
        checkForChanges(amount: transaction.amount, description: newDescription)
    }

    func saveChanges(amount: Double, description: String?) -> Result<Void, Error> {
        guard amount > 0 else {
            return .failure(NSError(domain: "TransactionDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Введіть коректну суму"]))
        }

        transaction.amount = amount
        transaction.transactionDescription = description

        let result = coreDataManager.saveContext()

        switch result {
        case .success:
            originalAmount = transaction.amount
            originalDescription = transaction.transactionDescription
            hasUnsavedChanges = false

            // Reload data after save
            if isExpense, let category = transaction.category {
                loadBudgetData(for: category)
            }
            if isIncome, let category = transaction.category {
                loadIncomeGoalData(for: category)
            }
            loadCategoryStats()

            NotificationCenter.default.post(name: .transactionDidAdd, object: nil)
            onChangesSaved?()
            return .success(())

        case .failure(let error):
            return .failure(error)
        }
    }

    func deleteTransaction() {
        let result = coreDataManager.delete(transaction)

        switch result {
        case .success:
            NotificationCenter.default.post(name: .transactionDidDelete, object: nil)
            onTransactionDeleted?()

        case .failure(let error):
            onError?(error)
        }
    }

    func getBudget() -> Budget? {
        guard let category = transaction.category else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let predicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d AND isActive == YES", category, month, year)
        let result = coreDataManager.fetch(Budget.self, predicate: predicate)

        switch result {
        case .success(let budgets):
            return budgets.first
        case .failure:
            return nil
        }
    }

    // MARK: - Private Methods

    private func checkForChanges(amount: Double, description: String?) {
        let descriptionChanged = description != originalDescription
        let amountChanged = abs(amount - originalAmount) > 0.001

        hasUnsavedChanges = descriptionChanged || amountChanged
    }

    private func loadBudgetData(for category: Category) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let predicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d AND isActive == YES", category, month, year)
        let result = coreDataManager.fetch(Budget.self, predicate: predicate)

        switch result {
        case .success(let budgets):
            if let budget = budgets.first {
                let spentAmount = getSpentAmount(for: category, month: month, year: year)
                let budgetAmount = budget.amount
                let remaining = budgetAmount - spentAmount
                let progress = Float(min(spentAmount / budgetAmount, 1.0))

                let progressTintColor: UIColor
                let remainingLabelColor: UIColor
                let remainingText: String

                if progress >= 1.0 {
                    progressTintColor = .systemRed
                    remainingLabelColor = .systemRed
                    remainingText = String(format: "Перевищено на %.2f ₴", abs(remaining))
                } else if progress >= 0.8 {
                    progressTintColor = .systemOrange
                    remainingLabelColor = .systemOrange
                    remainingText = String(format: "Залишилось %.2f ₴", remaining)
                } else {
                    progressTintColor = .systemGreen
                    remainingLabelColor = .systemGreen
                    remainingText = String(format: "Залишилось %.2f ₴", remaining)
                }

                budgetData = BudgetData(
                    progress: progress,
                    remaining: remaining,
                    progressTintColor: progressTintColor,
                    remainingLabelColor: remainingLabelColor,
                    remainingText: remainingText
                )
            } else {
                budgetData = nil
            }
        case .failure:
            budgetData = nil
        }
    }

    private func loadIncomeGoalData(for category: Category) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let predicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d AND isActive == YES", category, month, year)
        let result = coreDataManager.fetch(Budget.self, predicate: predicate)

        switch result {
        case .success(let budgets):
            if let goal = budgets.first {
                let achievedAmount = getIncomeAmount(for: category, month: month, year: year)
                let goalAmount = goal.amount
                let progress = Float(min(achievedAmount / goalAmount, 1.0))

                let progressTintColor: UIColor = progress >= 0.8 ? .systemGreen : .systemOrange
                let achievedLabelColor: UIColor = progress >= 0.8 ? .systemGreen : .systemOrange
                let achievedText = String(format: "Досягнуто %.2f ₴ (%.0f%%)", achievedAmount, progress * 100)

                incomeGoalData = IncomeGoalData(
                    progress: progress,
                    achieved: achievedAmount,
                    progressTintColor: progressTintColor,
                    achievedLabelColor: achievedLabelColor,
                    achievedText: achievedText
                )
            } else {
                incomeGoalData = nil
            }
        case .failure:
            incomeGoalData = nil
        }
    }

    private func loadCategoryStats() {
        guard let category = transaction.category else {
            categoryStatsData = nil
            return
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        var dateComponents = DateComponents()
        dateComponents.year = Int(year)
        dateComponents.month = Int(month)

        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            categoryStatsData = nil
            return
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, transaction.type ?? "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            let typeText = isExpense ? "витрачено" : "отримано"
            let totalText = String(format: "Всього %@: %.2f ₴", typeText, totalAmount)
            let countText = String(format: "Всього транзакцій: %d", transactions.count)

            categoryStatsData = CategoryStatsData(
                totalAmount: totalAmount,
                transactionsCount: transactions.count,
                totalText: totalText,
                countText: countText
            )
        case .failure:
            categoryStatsData = nil
        }
    }

    private func getSpentAmount(for category: Category, month: Int16, year: Int16) -> Double {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }

    private func getIncomeAmount(for category: Category, month: Int16, year: Int16) -> Double {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "income", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }
}
