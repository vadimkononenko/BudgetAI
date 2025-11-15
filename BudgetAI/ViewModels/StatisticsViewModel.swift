//
//  StatisticsViewModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation
import UIKit

/// View model for managing statistics screen data and business logic
final class StatisticsViewModel {

    // MARK: - Type Aliases

    typealias PeriodFilter = DateRangeCalculator.PeriodFilter
    typealias PeriodMenuItem = DateRangeCalculator.PeriodMenuItem
    typealias DailyExpense = ChartDataFormatter.DailyExpense
    typealias MonthlyData = ChartDataFormatter.MonthlyData

    // MARK: - Properties

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let dateRangeCalculator: DateRangeCalculator
    private let categoryStatsCalculator: CategoryStatsCalculator
    private let chartDataFormatter: ChartDataFormatter

    /// Currently selected period filter
    var selectedPeriod: PeriodFilter = .currentMonth

    /// Set of selected category names for filtering (empty means all categories)
    var selectedCategories: Set<String> = []

    /// Total income for the selected period
    var totalIncome: Double = 0

    /// Total expenses for the selected period
    var totalExpenses: Double = 0

    /// Balance (income - expenses) for the selected period
    var balance: Double = 0

    /// Top 5 category statistics
    var topCategoryStats: [CategoryStatDisplayModel] = []

    /// All category statistics
    var allCategoryStats: [CategoryStatDisplayModel] = []

    /// Available months with transactions
    var availableMonths: [(month: Int16, year: Int16)] = []

    // MARK: - Callbacks

    /// Callback triggered when data is updated
    var onDataUpdated: (() -> Void)?

    /// Callback triggered when an error occurs
    var onError: ((Error) -> Void)?

    /// Callback triggered when loading state changes
    var onLoading: ((Bool) -> Void)?

    // MARK: - Initialization

    /// Initializes the statistics view model with required dependencies
    /// - Parameters:
    ///   - transactionRepository: Repository for managing transactions
    ///   - categoryRepository: Repository for managing categories
    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.dateRangeCalculator = DateRangeCalculator(transactionRepository: transactionRepository)
        self.categoryStatsCalculator = CategoryStatsCalculator(transactionRepository: transactionRepository)
        self.chartDataFormatter = ChartDataFormatter(transactionRepository: transactionRepository)
    }

    // MARK: - Public Methods - Data Loading

    /// Loads all available months from transactions
    func loadAvailableMonths() {
        availableMonths = dateRangeCalculator.loadAvailableMonths()
    }

    /// Fetches statistics data for the selected period
    func fetchData() {
        onLoading?(true)

        let (startDate, endDate) = dateRangeCalculator.getDateRangeForPeriod(selectedPeriod)

        let totalsResult = categoryStatsCalculator.calculateTotals(from: startDate, to: endDate)

        onLoading?(false)

        switch totalsResult {
        case .success(let totals):
            totalIncome = totals.income
            totalExpenses = totals.expenses
            balance = totals.income - totals.expenses

            loadCategoryStats(from: startDate, to: endDate)
            onDataUpdated?()

        case .failure(let error):
            onError?(error)
        }
    }

    // MARK: - Public Methods - Period Management

    /// Sets the selected period and refreshes data
    /// - Parameter period: The period filter to set
    func setPeriod(_ period: PeriodFilter) {
        selectedPeriod = period
        fetchData()
    }

    /// Gets the localized title for the current period
    /// - Returns: Localized period title string
    func getPeriodTitle() -> String {
        return dateRangeCalculator.getPeriodTitle(for: selectedPeriod)
    }

    /// Gets the date range for the current period
    /// - Returns: Tuple containing start and end dates
    func getDateRange() -> (startDate: Date, endDate: Date) {
        return dateRangeCalculator.getDateRange(for: selectedPeriod)
    }

    /// Gets menu items for period selection
    /// - Returns: Array of period menu items
    func getPeriodMenuItems() -> [PeriodMenuItem] {
        return dateRangeCalculator.getPeriodMenuItems(
            availableMonths: availableMonths,
            selectedPeriod: selectedPeriod
        )
    }

    // MARK: - Public Methods - Formatting

    /// Gets formatted income string
    /// - Returns: Formatted currency string for total income
    func getFormattedIncome() -> String {
        return CurrencyFormatter.shared.format(totalIncome)
    }

    /// Gets formatted expenses string
    /// - Returns: Formatted currency string for total expenses
    func getFormattedExpenses() -> String {
        return CurrencyFormatter.shared.format(totalExpenses)
    }

    /// Gets formatted balance string
    /// - Returns: Formatted currency string for balance
    func getFormattedBalance() -> String {
        return CurrencyFormatter.shared.format(balance)
    }

    /// Gets color for balance display
    /// - Returns: Green for positive/zero balance, red for negative
    func getBalanceColor() -> UIColor {
        return balance >= 0 ? .systemGreen : .systemRed
    }

    // MARK: - Public Methods - Category Statistics

    /// Checks if there are more than 5 categories
    /// - Returns: True if there are more than 5 categories
    func hasMoreThan5Categories() -> Bool {
        return allCategoryStats.count > 5
    }

    /// Checks if there is any data to display
    /// - Returns: True if there is income or expenses
    func hasData() -> Bool {
        return totalIncome > 0 || totalExpenses > 0
    }

    /// Gets category at the specified index
    /// - Parameter index: Index in the top category stats array
    /// - Returns: Category object or nil if index is out of bounds
    func getCategory(at index: Int) -> Category? {
        guard index < topCategoryStats.count else { return nil }
        return topCategoryStats[index].category
    }

    /// Gets filtered category statistics
    /// - Returns: Array of category statistics filtered by selected categories
    func getFilteredCategoryStats() -> [CategoryStatDisplayModel] {
        return categoryStatsCalculator.getFilteredCategoryStats(
            from: allCategoryStats,
            selectedCategories: selectedCategories
        )
    }

    /// Gets all category names
    /// - Returns: Array of all category names
    func getAllCategories() -> [String] {
        return categoryStatsCalculator.getAllCategoryNames(from: allCategoryStats)
    }

    // MARK: - Public Methods - Category Filtering

    /// Toggles category filter selection
    /// - Parameter categoryName: Name of the category to toggle
    func toggleCategoryFilter(_ categoryName: String) {
        selectedCategories = categoryStatsCalculator.toggleCategoryFilter(
            categoryName,
            in: selectedCategories
        )
        onDataUpdated?()
    }

    /// Clears all category filters
    func clearCategoryFilter() {
        selectedCategories.removeAll()
        onDataUpdated?()
    }

    /// Checks if a category is selected
    /// - Parameter categoryName: Name of the category to check
    /// - Returns: True if category is selected or no filters are applied
    func isCategorySelected(_ categoryName: String) -> Bool {
        return categoryStatsCalculator.isCategorySelected(categoryName, in: selectedCategories)
    }

    // MARK: - Public Methods - Chart Data

    /// Gets daily expense data for charts
    /// - Returns: Array of daily expense data sorted by date
    func getDailyExpenses() -> [DailyExpense] {
        let (startDate, endDate) = dateRangeCalculator.getDateRangeForPeriod(selectedPeriod)

        return chartDataFormatter.getDailyExpenses(
            for: selectedPeriod,
            startDate: startDate,
            endDate: endDate,
            selectedCategories: selectedCategories
        )
    }

    /// Gets monthly comparison data for charts
    /// - Returns: Array of monthly data sorted by date
    func getMonthlyComparisonData() -> [MonthlyData] {
        return chartDataFormatter.getMonthlyComparisonData(selectedCategories: selectedCategories)
    }

    // MARK: - Private Methods

    /// Loads category statistics for the specified period
    /// - Parameters:
    ///   - startDate: Start date of the period (optional)
    ///   - endDate: End date of the period (optional)
    private func loadCategoryStats(from startDate: Date?, to endDate: Date?) {
        let statsResult = categoryStatsCalculator.calculateCategoryStats(
            from: startDate,
            to: endDate,
            totalExpenses: totalExpenses
        )

        switch statsResult {
        case .success(let stats):
            allCategoryStats = stats
            topCategoryStats = categoryStatsCalculator.getTopCategories(from: stats, limit: 5)

        case .failure(let error):
            onError?(error)
        }
    }
}
