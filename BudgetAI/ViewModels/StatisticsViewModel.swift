//
//  StatisticsViewModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation
import UIKit

final class StatisticsViewModel {

    // MARK: - Properties

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository

    enum PeriodFilter: Equatable {
        case currentMonth
        case specificMonth(month: Int16, year: Int16)
        case currentYear
        case allTime
    }

    struct PeriodMenuItem {
        let title: String
        let period: PeriodFilter
        let isSelected: Bool
    }

    var selectedPeriod: PeriodFilter = .currentMonth
    var totalIncome: Double = 0
    var totalExpenses: Double = 0
    var balance: Double = 0
    var topCategoryStats: [CategoryStatDisplayModel] = []
    var allCategoryStats: [CategoryStatDisplayModel] = []
    var availableMonths: [(month: Int16, year: Int16)] = []

    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoading: ((Bool) -> Void)?

    // MARK: - Initialization

    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Public Methods

    func loadAvailableMonths() {
        let result = transactionRepository.fetchAllTransactions()

        switch result {
        case .success(let transactions):
            let calendar = Calendar.current
            var monthYearSet: Set<String> = []
            var monthsArray: [(month: Int16, year: Int16)] = []

            for transaction in transactions {
                let components = calendar.dateComponents([.month, .year], from: transaction.date ?? Date())
                let month = Int16(components.month ?? 1)
                let year = Int16(components.year ?? 2025)
                let key = "\(year)-\(month)"

                if !monthYearSet.contains(key) {
                    monthYearSet.insert(key)
                    monthsArray.append((month: month, year: year))
                }
            }

            availableMonths = monthsArray.sorted { first, second in
                if first.year != second.year {
                    return first.year > second.year
                }
                return first.month > second.month
            }

        case .failure(let error):
            onError?(error)
        }
    }

    func fetchData() {
        onLoading?(true)

        let (startDate, endDate) = getDateRangeForPeriod()

        let incomeResult = transactionRepository.calculateTotalIncome(from: startDate, to: endDate)
        let expensesResult = transactionRepository.calculateTotalExpenses(from: startDate, to: endDate)

        onLoading?(false)

        switch (incomeResult, expensesResult) {
        case (.success(let income), .success(let expenses)):
            totalIncome = income
            totalExpenses = expenses
            balance = income - expenses

            calculateCategoryStats(from: startDate, to: endDate)
            onDataUpdated?()

        case (.failure(let error), _), (_, .failure(let error)):
            onError?(error)
        }
    }

    func setPeriod(_ period: PeriodFilter) {
        selectedPeriod = period
        fetchData()
    }

    func getPeriodTitle() -> String {
        switch selectedPeriod {
        case .currentMonth:
            return "Поточний місяць"
        case .specificMonth(let month, let year):
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let date = calendar.date(from: components) else {
                return "Невідомий період"
            }

            return DateFormatter.monthYear.string(from: date).capitalized
        case .currentYear:
            return "Поточний рік"
        case .allTime:
            return "За весь час"
        }
    }

    func getFormattedIncome() -> String {
        return CurrencyFormatter.shared.format(totalIncome)
    }

    func getFormattedExpenses() -> String {
        return CurrencyFormatter.shared.format(totalExpenses)
    }

    func getFormattedBalance() -> String {
        return CurrencyFormatter.shared.format(balance)
    }

    func hasMoreThan5Categories() -> Bool {
        return allCategoryStats.count > 5
    }

    func hasData() -> Bool {
        return totalIncome > 0 || totalExpenses > 0
    }

    func getBalanceColor() -> UIColor {
        return balance >= 0 ? .systemGreen : .systemRed
    }

    func getCategory(at index: Int) -> Category? {
        guard index < topCategoryStats.count else { return nil }
        return topCategoryStats[index].category
    }

    func getDateRange() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .currentMonth:
            let components = calendar.dateComponents([.year, .month], from: Date())
            if let startOfMonth = calendar.date(from: components),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
                return (startOfMonth, endOfMonth)
            }

        case .specificMonth(let month, let year):
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            if let startOfMonth = calendar.date(from: components),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
                return (startOfMonth, endOfMonth)
            }

        case .currentYear:
            let components = calendar.dateComponents([.year], from: Date())
            if let startOfYear = calendar.date(from: components) {
                let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) ?? Date()
                return (startOfYear, endOfYear)
            }

        case .allTime:
            // Get the earliest and latest transaction dates
            let result = transactionRepository.fetchAllTransactions()

            switch result {
            case .success(let transactions):
                if let earliest = transactions.min(by: { $0.date ?? Date() < $1.date ?? Date() })?.date,
                   let latest = transactions.max(by: { $0.date ?? Date() < $1.date ?? Date() })?.date {
                    return (earliest, latest)
                }
            case .failure:
                break
            }
        }

        // Fallback to current month
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let startOfMonth = calendar.date(from: components),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
            return (startOfMonth, endOfMonth)
        }

        // Final fallback
        return (Date(), Date())
    }

    func getPeriodMenuItems() -> [PeriodMenuItem] {
        var menuItems: [PeriodMenuItem] = []

        // Current month
        menuItems.append(PeriodMenuItem(
            title: "Поточний місяць",
            period: .currentMonth,
            isSelected: selectedPeriod == .currentMonth
        ))

        // Specific months
        for monthYear in availableMonths {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(monthYear.year)
            components.month = Int(monthYear.month)

            guard let date = calendar.date(from: components) else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "uk_UA")
            dateFormatter.dateFormat = "LLLL yyyy"
            let title = dateFormatter.string(from: date).capitalized

            var isSelected = false
            if case .specificMonth(let month, let year) = selectedPeriod {
                isSelected = (month == monthYear.month && year == monthYear.year)
            }

            menuItems.append(PeriodMenuItem(
                title: title,
                period: .specificMonth(month: monthYear.month, year: monthYear.year),
                isSelected: isSelected
            ))
        }

        // Current year
        menuItems.append(PeriodMenuItem(
            title: "Поточний рік",
            period: .currentYear,
            isSelected: selectedPeriod == .currentYear
        ))

        // All time
        menuItems.append(PeriodMenuItem(
            title: "За весь час",
            period: .allTime,
            isSelected: selectedPeriod == .allTime
        ))

        return menuItems
    }

    // MARK: - Private Methods

    private func getDateRangeForPeriod() -> (Date?, Date?) {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .currentMonth:
            let components = calendar.dateComponents([.year, .month], from: Date())
            guard let startOfMonth = calendar.date(from: components) else {
                return (nil, nil)
            }
            return (startOfMonth, nil)

        case .specificMonth(let month, let year):
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return (nil, nil)
            }
            return (startOfMonth, endOfMonth)

        case .currentYear:
            let components = calendar.dateComponents([.year], from: Date())
            guard let startOfYear = calendar.date(from: components) else {
                return (nil, nil)
            }
            return (startOfYear, nil)

        case .allTime:
            return (nil, nil)
        }
    }

    private func calculateCategoryStats(from startDate: Date?, to endDate: Date?) {
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

            allCategoryStats = Array(categoryAmounts.values)
                .map { CategoryStatDisplayModel(category: $0.category, amount: $0.amount, totalExpenses: totalExpenses) }
                .sorted { $0.amountRaw > $1.amountRaw }

            topCategoryStats = Array(allCategoryStats.prefix(5))

        case .failure(let error):
            onError?(error)
        }
    }
}
