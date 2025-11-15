//
//  ExpenseDataAggregator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation
import CoreData

/// Represents aggregated expense data for a specific month and category
struct MonthlyExpenseData {
    /// Year of the expense data
    let year: Int

    /// Month of the expense data (1-12)
    let month: Int

    /// Name of the expense category
    let categoryName: String

    /// Total amount spent in this category for this month
    let totalAmount: Double

    /// Average amount spent in the last 3 months for this category
    let averageLastThreeMonths: Double

    /// Season identifier (1 = Winter, 2 = Spring, 3 = Summer, 4 = Fall)
    let season: Int

    /// Formatted month key in YYYY-MM format
    var monthKey: String {
        return "\(year)-\(String(format: "%02d", month))"
    }
}

/// Aggregates and prepares expense data for machine learning model training and forecasting
/// Processes transaction data into monthly aggregates with calculated features
final class ExpenseDataAggregator {

    /// Repository for accessing transaction data
    private let transactionRepository: TransactionRepository

    /// Repository for accessing category data
    private let categoryRepository: CategoryRepository

    /// Initializes the expense data aggregator
    /// - Parameters:
    ///   - transactionRepository: Repository for accessing transaction data
    ///   - categoryRepository: Repository for accessing category data
    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Public Methods

    /// Aggregates historical expense data by months and categories
    /// Calculates total amounts, 3-month averages, and seasonal data for ML model training
    /// - Returns: Result containing array of monthly expense data or error
    func aggregateMonthlyExpenses() -> Result<[MonthlyExpenseData], CoreDataError> {
        // Get all transactions
        guard case .success(let allTransactions) = transactionRepository.fetchAllTransactions() else {
            return .failure(.fetchFailed(NSError(domain: "ExpenseDataAggregator", code: 1, userInfo: nil)))
        }

        // Filter only expenses
        let expenses = allTransactions.filter { $0.type == "expense" }

        // Group by months and categories
        var monthlyData: [String: [String: Double]] = [:] // [monthKey: [categoryName: totalAmount]]

        for expense in expenses {
            guard let date = expense.date,
                  let categoryName = expense.category?.name else {
                continue
            }

            let components = Calendar.current.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { continue }

            let monthKey = "\(year)-\(String(format: "%02d", month))"

            if monthlyData[monthKey] == nil {
                monthlyData[monthKey] = [:]
            }

            let currentAmount = monthlyData[monthKey]?[categoryName] ?? 0.0
            monthlyData[monthKey]?[categoryName] = currentAmount + expense.amount
        }

        // Create array of MonthlyExpenseData with average calculations
        var result: [MonthlyExpenseData] = []

        // Sort months for correct average calculation
        let sortedMonthKeys = monthlyData.keys.sorted()

        // For each month and category, calculate 3-month average
        for monthKey in sortedMonthKeys {
            guard let categories = monthlyData[monthKey] else { continue }

            let components = monthKey.split(separator: "-")
            guard components.count == 2,
                  let year = Int(components[0]),
                  let month = Int(components[1]) else {
                continue
            }

            for (categoryName, totalAmount) in categories {
                let average = calculateAverageLastThreeMonths(
                    categoryName: categoryName,
                    currentYear: year,
                    currentMonth: month,
                    monthlyData: monthlyData
                )

                let season = getSeason(month: month)

                let data = MonthlyExpenseData(
                    year: year,
                    month: month,
                    categoryName: categoryName,
                    totalAmount: totalAmount,
                    averageLastThreeMonths: average,
                    season: season
                )

                result.append(data)
            }
        }

        return .success(result)
    }

    /// Exports aggregated expense data in CSV format for CreateML training
    /// - Returns: Result containing URL of exported CSV file or error
    /// - Note: Requires minimum 3 months of historical data
    func exportToCSV() -> Result<URL, Error> {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return .failure(NSError(domain: "ExpenseDataAggregator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to aggregate data"]))
        }

        // Minimum 3 months of history required for training
        guard data.count >= 3 else {
            return .failure(NSError(domain: "ExpenseDataAggregator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Not enough historical data. At least 3 months required."]))
        }

        var csvString = "year,month,category,averageLastThreeMonths,season,totalAmount\n"

        for item in data {
            let row = "\(item.year),\(item.month),\(item.categoryName),\(item.averageLastThreeMonths),\(item.season),\(item.totalAmount)\n"
            csvString.append(row)
        }

        // Save file to temporary directory
        let fileName = "expense_training_data.csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            return .failure(error)
        }
    }

    /// Checks if there's enough historical data for ML-based forecasting
    /// - Returns: True if at least 3 months of expense data is available, false otherwise
    func hasEnoughDataForForecasting() -> Bool {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return false
        }

        // Minimum 3 months of history required for ML model
        let uniqueMonths = Set(data.map { $0.monthKey })
        return uniqueMonths.count >= 3
    }

    /// Returns the number of unique months with expense data
    /// - Returns: Count of unique months that have expense transactions
    func getMonthsOfDataCount() -> Int {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return 0
        }

        let uniqueMonths = Set(data.map { $0.monthKey })
        return uniqueMonths.count
    }

    /// Checks if there's any expense data available
    /// - Returns: True if at least one month of expense data exists, false otherwise
    func hasAnyData() -> Bool {
        return getMonthsOfDataCount() > 0
    }

    // MARK: - Private Helpers

    private func calculateAverageLastThreeMonths(
        categoryName: String,
        currentYear: Int,
        currentMonth: Int,
        monthlyData: [String: [String: Double]]
    ) -> Double {
        var amounts: [Double] = []

        // Generate last 3 months (not including current)
        for i in 1...3 {
            var targetMonth = currentMonth - i
            var targetYear = currentYear

            if targetMonth <= 0 {
                targetMonth += 12
                targetYear -= 1
            }

            let monthKey = "\(targetYear)-\(String(format: "%02d", targetMonth))"

            if let amount = monthlyData[monthKey]?[categoryName] {
                amounts.append(amount)
            }
        }

        guard !amounts.isEmpty else { return 0.0 }

        return amounts.reduce(0, +) / Double(amounts.count)
    }

    private func getSeason(month: Int) -> Int {
        switch month {
        case 12, 1, 2: return 1 // Winter
        case 3, 4, 5: return 2  // Spring
        case 6, 7, 8: return 3  // Summer
        case 9, 10, 11: return 4 // Fall
        default: return 1
        }
    }
}
