//
//  DateRangeCalculator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import Foundation

/// Service responsible for calculating date ranges based on different period filters
final class DateRangeCalculator {

    // MARK: - Types

    /// Period filter options for statistics calculations
    enum PeriodFilter: Equatable {
        case currentMonth
        case specificMonth(month: Int16, year: Int16)
        case currentYear
        case allTime
    }

    /// Represents a menu item for period selection
    struct PeriodMenuItem {
        let title: String
        let period: PeriodFilter
        let isSelected: Bool
    }

    // MARK: - Properties

    private let transactionRepository: TransactionRepository
    private let calendar: Calendar

    // MARK: - Initialization

    /// Initializes the date range calculator with required dependencies
    /// - Parameter transactionRepository: Repository for fetching transactions
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
        self.calendar = Calendar.current
    }

    // MARK: - Public Methods

    /// Calculates date range for the specified period filter
    /// - Parameter period: The period filter to calculate dates for
    /// - Returns: Tuple containing optional start and end dates
    func getDateRangeForPeriod(_ period: PeriodFilter) -> (Date?, Date?) {
        switch period {
        case .currentMonth:
            return getCurrentMonthRange()

        case .specificMonth(let month, let year):
            return getSpecificMonthRange(month: month, year: year)

        case .currentYear:
            return getCurrentYearRange()

        case .allTime:
            return (nil, nil)
        }
    }

    /// Gets the full date range (start and end) for the specified period
    /// - Parameter period: The period filter to calculate dates for
    /// - Returns: Tuple containing start and end dates (with fallback to current month)
    func getDateRange(for period: PeriodFilter) -> (startDate: Date, endDate: Date) {
        switch period {
        case .currentMonth:
            return getCurrentMonthFullRange()

        case .specificMonth(let month, let year):
            return getSpecificMonthFullRange(month: month, year: year)

        case .currentYear:
            return getCurrentYearFullRange()

        case .allTime:
            return getAllTimeRange()
        }
    }

    /// Gets localized title for the specified period
    /// - Parameter period: The period filter to get title for
    /// - Returns: Localized string representing the period
    func getPeriodTitle(for period: PeriodFilter) -> String {
        switch period {
        case .currentMonth:
            return "Current Month"

        case .specificMonth(let month, let year):
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let date = calendar.date(from: components) else {
                return "Unknown Period"
            }

            return DateFormatter.monthYear.string(from: date).capitalized

        case .currentYear:
            return "Current Year"

        case .allTime:
            return "All Time"
        }
    }

    /// Loads all available months from transactions
    /// - Returns: Array of tuples containing month and year values, sorted descending
    func loadAvailableMonths() -> [(month: Int16, year: Int16)] {
        let result = transactionRepository.fetchAllTransactions()

        switch result {
        case .success(let transactions):
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

            return monthsArray.sorted { first, second in
                if first.year != second.year {
                    return first.year > second.year
                }
                return first.month > second.month
            }

        case .failure:
            return []
        }
    }

    /// Generates menu items for period selection
    /// - Parameters:
    ///   - availableMonths: Array of available month/year tuples
    ///   - selectedPeriod: Currently selected period filter
    /// - Returns: Array of period menu items
    func getPeriodMenuItems(
        availableMonths: [(month: Int16, year: Int16)],
        selectedPeriod: PeriodFilter
    ) -> [PeriodMenuItem] {
        var menuItems: [PeriodMenuItem] = []

        // Current month
        menuItems.append(PeriodMenuItem(
            title: "Current Month",
            period: .currentMonth,
            isSelected: selectedPeriod == .currentMonth
        ))

        // Specific months
        for monthYear in availableMonths {
            var components = DateComponents()
            components.year = Int(monthYear.year)
            components.month = Int(monthYear.month)

            guard let date = calendar.date(from: components) else { continue }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
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
            title: "Current Year",
            period: .currentYear,
            isSelected: selectedPeriod == .currentYear
        ))

        // All time
        menuItems.append(PeriodMenuItem(
            title: "All Time",
            period: .allTime,
            isSelected: selectedPeriod == .allTime
        ))

        return menuItems
    }

    // MARK: - Private Methods

    /// Calculates current month date range (start to nil)
    /// - Returns: Tuple with start of current month and nil end date
    private func getCurrentMonthRange() -> (Date?, Date?) {
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else {
            return (nil, nil)
        }
        return (startOfMonth, nil)
    }

    /// Calculates current month full date range (start to end)
    /// - Returns: Tuple with start and end of current month (or current date as fallback)
    private func getCurrentMonthFullRange() -> (Date, Date) {
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let startOfMonth = calendar.date(from: components),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
            return (startOfMonth, endOfMonth)
        }
        return (Date(), Date())
    }

    /// Calculates specific month date range
    /// - Parameters:
    ///   - month: Month value (1-12)
    ///   - year: Year value
    /// - Returns: Tuple with start and end of specified month
    private func getSpecificMonthRange(month: Int16, year: Int16) -> (Date?, Date?) {
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return (nil, nil)
        }
        return (startOfMonth, endOfMonth)
    }

    /// Calculates specific month full date range
    /// - Parameters:
    ///   - month: Month value (1-12)
    ///   - year: Year value
    /// - Returns: Tuple with start and end of specified month (or current date as fallback)
    private func getSpecificMonthFullRange(month: Int16, year: Int16) -> (Date, Date) {
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        if let startOfMonth = calendar.date(from: components),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
            return (startOfMonth, endOfMonth)
        }
        return (Date(), Date())
    }

    /// Calculates current year date range (start to nil)
    /// - Returns: Tuple with start of current year and nil end date
    private func getCurrentYearRange() -> (Date?, Date?) {
        let components = calendar.dateComponents([.year], from: Date())
        guard let startOfYear = calendar.date(from: components) else {
            return (nil, nil)
        }
        return (startOfYear, nil)
    }

    /// Calculates current year full date range
    /// - Returns: Tuple with start and end of current year
    private func getCurrentYearFullRange() -> (Date, Date) {
        let components = calendar.dateComponents([.year], from: Date())
        if let startOfYear = calendar.date(from: components) {
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) ?? Date()
            return (startOfYear, endOfYear)
        }
        return (Date(), Date())
    }

    /// Calculates all-time date range based on earliest and latest transactions
    /// - Returns: Tuple with earliest and latest transaction dates (or current date as fallback)
    private func getAllTimeRange() -> (Date, Date) {
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

        // Fallback to current month if no transactions found
        return getCurrentMonthFullRange()
    }
}
