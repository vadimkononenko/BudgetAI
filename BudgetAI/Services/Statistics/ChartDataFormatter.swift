//
//  ChartDataFormatter.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import Foundation

/// Service responsible for formatting data for chart visualizations
final class ChartDataFormatter {

    // MARK: - Types

    /// Represents daily expense data for charts
    struct DailyExpense: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
    }

    /// Represents monthly comparison data for charts
    struct MonthlyData: Identifiable {
        let id = UUID()
        let month: String
        let date: Date
        let income: Double
        let expense: Double

        /// Calculated balance (income - expense)
        var balance: Double {
            return income - expense
        }
    }

    // MARK: - Properties

    private let transactionRepository: TransactionRepository
    private let calendar: Calendar

    // MARK: - Initialization

    /// Initializes the chart data formatter with required dependencies
    /// - Parameter transactionRepository: Repository for fetching transactions
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
        self.calendar = Calendar.current
    }

    // MARK: - Public Methods

    /// Generates daily expense data for the specified period
    /// - Parameters:
    ///   - period: Period filter for date range calculation
    ///   - startDate: Start date of the period (optional)
    ///   - endDate: End date of the period (optional)
    ///   - selectedCategories: Set of selected category names for filtering
    /// - Returns: Array of daily expense data sorted by date
    func getDailyExpenses(
        for period: DateRangeCalculator.PeriodFilter,
        startDate: Date?,
        endDate: Date?,
        selectedCategories: Set<String>
    ) -> [DailyExpense] {
        let transactionsResult: Result<[Transaction], CoreDataError>

        if let startDate = startDate, let endDate = endDate {
            transactionsResult = transactionRepository.fetchTransactions(from: startDate, to: endDate)
        } else if let startDate = startDate {
            transactionsResult = transactionRepository.fetchTransactions(from: startDate, to: Date())
        } else {
            transactionsResult = transactionRepository.fetchAllTransactions()
        }

        guard case .success(let transactions) = transactionsResult else {
            return []
        }

        let expenses = transactions.filter { $0.type == "expense" }
        let filteredExpenses = filterBySelectedCategories(expenses, selectedCategories: selectedCategories)

        var dailyExpenseDict: [Date: Double] = [:]

        for expense in filteredExpenses {
            guard let date = expense.date else { continue }

            let normalizedDate = normalizeDate(date, for: period)
            dailyExpenseDict[normalizedDate, default: 0] += expense.amount
        }

        return dailyExpenseDict.map { DailyExpense(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// Generates monthly comparison data across all available months
    /// - Parameter selectedCategories: Set of selected category names for filtering expenses
    /// - Returns: Array of monthly data sorted by date
    func getMonthlyComparisonData(selectedCategories: Set<String>) -> [MonthlyData] {
        let result = transactionRepository.fetchAllTransactions()

        guard case .success(let transactions) = result else {
            return []
        }

        var monthlyDict: [String: (date: Date, income: Double, expense: Double)] = [:]

        for transaction in transactions {
            guard let date = transaction.date else { continue }

            let components = calendar.dateComponents([.year, .month], from: date)
            guard let normalizedDate = calendar.date(from: components) else { continue }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM yy"
            let key = formatter.string(from: normalizedDate)

            if monthlyDict[key] == nil {
                monthlyDict[key] = (date: normalizedDate, income: 0, expense: 0)
            }

            if transaction.type == "income" {
                monthlyDict[key]?.income += transaction.amount
            } else if transaction.type == "expense" {
                // Apply category filter
                if selectedCategories.isEmpty || selectedCategories.contains(transaction.category?.name ?? "") {
                    monthlyDict[key]?.expense += transaction.amount
                }
            }
        }

        return monthlyDict.map { key, value in
            MonthlyData(
                month: key,
                date: value.date,
                income: value.income,
                expense: value.expense
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Private Methods

    /// Normalizes date based on the period filter
    /// - Parameters:
    ///   - date: Date to normalize
    ///   - period: Period filter determining normalization granularity
    /// - Returns: Normalized date (day-level for month periods, month-level for year/all-time)
    private func normalizeDate(_ date: Date, for period: DateRangeCalculator.PeriodFilter) -> Date {
        let components: Set<Calendar.Component>

        switch period {
        case .currentMonth, .specificMonth:
            // Group by day for month views
            components = [.year, .month, .day]
        case .currentYear, .allTime:
            // Group by month for year/all-time views
            components = [.year, .month]
        }

        let dateComponents = calendar.dateComponents(components, from: date)
        return calendar.date(from: dateComponents) ?? date
    }

    /// Filters transactions by selected categories
    /// - Parameters:
    ///   - transactions: Array of transactions to filter
    ///   - selectedCategories: Set of selected category names (empty means all)
    /// - Returns: Filtered array of transactions
    private func filterBySelectedCategories(
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
