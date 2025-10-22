//
//  ExpenseDataAggregator.swift
//  BudgetAI
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import CoreData

struct MonthlyExpenseData {
    let year: Int
    let month: Int
    let categoryName: String
    let totalAmount: Double
    let averageLastThreeMonths: Double
    let season: Int // 1 = Winter, 2 = Spring, 3 = Summer, 4 = Fall

    var monthKey: String {
        return "\(year)-\(String(format: "%02d", month))"
    }
}

final class ExpenseDataAggregator {

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository

    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Public Methods

    /// Агрегує історичні дані по місяцях та категоріях
    func aggregateMonthlyExpenses() -> Result<[MonthlyExpenseData], CoreDataError> {
        // Отримуємо всі транзакції
        guard case .success(let allTransactions) = transactionRepository.fetchAllTransactions() else {
            return .failure(.fetchFailed(NSError(domain: "ExpenseDataAggregator", code: 1, userInfo: nil)))
        }

        // Фільтруємо тільки витрати
        let expenses = allTransactions.filter { $0.type == "expense" }

        // Групуємо по місяцях та категоріях
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

        // Створюємо масив MonthlyExpenseData з розрахунком середніх
        var result: [MonthlyExpenseData] = []

        // Сортуємо місяці для правильного розрахунку середніх
        let sortedMonthKeys = monthlyData.keys.sorted()

        // Для кожного місяця та категорії розраховуємо середнє за 3 місяці
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

    /// Експортує дані у форматі CSV для CreateML
    func exportToCSV() -> Result<URL, Error> {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return .failure(NSError(domain: "ExpenseDataAggregator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to aggregate data"]))
        }

        // Мінімум 3 місяці історії потрібно для тренування
        guard data.count >= 3 else {
            return .failure(NSError(domain: "ExpenseDataAggregator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Not enough historical data. At least 3 months required."]))
        }

        var csvString = "year,month,category,averageLastThreeMonths,season,totalAmount\n"

        for item in data {
            let row = "\(item.year),\(item.month),\(item.categoryName),\(item.averageLastThreeMonths),\(item.season),\(item.totalAmount)\n"
            csvString.append(row)
        }

        // Зберігаємо файл у тимчасову директорію
        let fileName = "expense_training_data.csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            return .failure(error)
        }
    }

    /// Перевіряє чи достатньо даних для прогнозування
    func hasEnoughDataForForecasting() -> Bool {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return false
        }

        // Потрібно мінімум 3 місяці історії для ML моделі
        let uniqueMonths = Set(data.map { $0.monthKey })
        return uniqueMonths.count >= 3
    }

    /// Повертає кількість місяців з даними
    func getMonthsOfDataCount() -> Int {
        guard case .success(let data) = aggregateMonthlyExpenses() else {
            return 0
        }

        let uniqueMonths = Set(data.map { $0.monthKey })
        return uniqueMonths.count
    }

    /// Перевіряє чи є хоч якісь дані
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

        // Генеруємо останні 3 місяці (не включаючи поточний)
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
