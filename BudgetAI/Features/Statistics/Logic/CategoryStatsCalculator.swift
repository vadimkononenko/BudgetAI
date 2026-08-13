//
//  CategoryStatsCalculator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import Foundation

/// Service responsible for calculating category-based statistics
final class CategoryStatsCalculator {

    // MARK: - Properties

    private let transactionRepository: TransactionRepository

    // MARK: - Initialization

    /// Initializes the category statistics calculator with required dependencies
    /// - Parameter transactionRepository: Repository for fetching transactions
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    // MARK: - Public Methods

    /// Calculates total income and expenses for the specified period
    /// - Parameters:
    ///   - startDate: Start date of the period (optional)
    ///   - endDate: End date of the period (optional)
    /// - Returns: Result containing tuple of income and expenses or an error
    func calculateTotals(
        from startDate: Date?,
        to endDate: Date?
    ) -> Result<(income: Double, expenses: Double), CoreDataError> {
        let incomeResult = transactionRepository.calculateTotalIncome(from: startDate, to: endDate)
        let expensesResult = transactionRepository.calculateTotalExpenses(from: startDate, to: endDate)

        switch (incomeResult, expensesResult) {
        case (.success(let income), .success(let expenses)):
            return .success((income: income, expenses: expenses))

        case (.failure(let error), _):
            return .failure(error)

        case (_, .failure(let error)):
            return .failure(error)
        }
    }

    /// Calculates category statistics for the specified period
    /// - Parameters:
    ///   - startDate: Start date of the period (optional)
    ///   - endDate: End date of the period (optional)
    ///   - totalExpenses: Total expenses amount for percentage calculation
    /// - Returns: Result containing array of all category statistics or an error
    func calculateCategoryStats(
        from startDate: Date?,
        to endDate: Date?,
        totalExpenses: Double
    ) -> Result<[CategoryStatDisplayModel], CoreDataError> {
        let transactionsResult: Result<[Transaction], CoreDataError>

        if let startDate = startDate, let endDate = endDate {
            transactionsResult = transactionRepository.fetchTransactions(from: startDate, to: endDate)
        } else if let startDate = startDate {
            // From startDate to now
            transactionsResult = transactionRepository.fetchTransactions(from: startDate, to: Date())
        } else {
            transactionsResult = transactionRepository.fetchAllTransactions()
        }

        switch transactionsResult {
        case .success(let transactions):
            let expenses = transactions.filter { $0.type == "expense" }
            var categoryAmounts: [String: (category: Category, amount: Double)] = [:]

            for expense in expenses {
                guard let category = expense.category else { continue }
                let categoryName = category.name ?? ""

                if let existing = categoryAmounts[categoryName] {
                    categoryAmounts[categoryName] = (category, existing.amount + expense.amount)
                } else {
                    categoryAmounts[categoryName] = (category, expense.amount)
                }
            }

            let stats = Array(categoryAmounts.values)
                .map { CategoryStatDisplayModel(category: $0.category, amount: $0.amount, totalExpenses: totalExpenses) }
                .sorted { $0.amountRaw > $1.amountRaw }

            return .success(stats)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Gets top N categories by expense amount
    /// - Parameters:
    ///   - allStats: All category statistics
    ///   - limit: Maximum number of categories to return
    /// - Returns: Array of top category statistics
    func getTopCategories(from allStats: [CategoryStatDisplayModel], limit: Int = 5) -> [CategoryStatDisplayModel] {
        return Array(allStats.prefix(limit))
    }

    /// Filters category statistics by selected categories
    /// - Parameters:
    ///   - allStats: All category statistics
    ///   - selectedCategories: Set of selected category names (empty means all)
    /// - Returns: Filtered array of category statistics
    func getFilteredCategoryStats(
        from allStats: [CategoryStatDisplayModel],
        selectedCategories: Set<String>
    ) -> [CategoryStatDisplayModel] {
        if selectedCategories.isEmpty {
            return allStats
        } else {
            return allStats.filter { selectedCategories.contains($0.categoryName) }
        }
    }

    /// Gets all category names from statistics
    /// - Parameter allStats: All category statistics
    /// - Returns: Array of category names
    func getAllCategoryNames(from allStats: [CategoryStatDisplayModel]) -> [String] {
        return allStats.map { $0.categoryName }
    }

    /// Checks if a category is selected
    /// - Parameters:
    ///   - categoryName: Name of the category to check
    ///   - selectedCategories: Set of selected category names
    /// - Returns: True if category is selected or if no categories are selected (all selected)
    func isCategorySelected(_ categoryName: String, in selectedCategories: Set<String>) -> Bool {
        return selectedCategories.isEmpty || selectedCategories.contains(categoryName)
    }

    /// Toggles category selection state
    /// - Parameters:
    ///   - categoryName: Name of the category to toggle
    ///   - selectedCategories: Current set of selected categories
    /// - Returns: Updated set of selected categories
    func toggleCategoryFilter(_ categoryName: String, in selectedCategories: Set<String>) -> Set<String> {
        var updatedCategories = selectedCategories

        if updatedCategories.contains(categoryName) {
            updatedCategories.remove(categoryName)
        } else {
            updatedCategories.insert(categoryName)
        }

        return updatedCategories
    }

    /// Filters transactions by selected categories
    /// - Parameters:
    ///   - transactions: Array of transactions to filter
    ///   - selectedCategories: Set of selected category names (empty means all)
    /// - Returns: Filtered array of transactions
    func filterTransactionsByCategories(
        _ transactions: [Transaction],
        selectedCategories: Set<String>
    ) -> [Transaction] {
        if selectedCategories.isEmpty {
            return transactions
        }

        return transactions.filter { transaction in
            guard let categoryName = transaction.category?.name else { return false }
            return selectedCategories.contains(categoryName)
        }
    }
}
