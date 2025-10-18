//
//  BudgetViewModel.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation

final class BudgetViewModel {

    // MARK: - Properties

    private let budgetRepository: BudgetRepository
    private let categoryRepository: CategoryRepository

    var budgets: [BudgetDisplayModel] = []
    var currentMonth: Int16 = 0
    var currentYear: Int16 = 0
    var selectedMonth: Int16 = 0
    var selectedYear: Int16 = 0
    var isCurrentMonth: Bool { selectedMonth == currentMonth && selectedYear == currentYear }

    var onBudgetsUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoading: ((Bool) -> Void)?

    // MARK: - Initialization

    init(budgetRepository: BudgetRepository, categoryRepository: CategoryRepository) {
        self.budgetRepository = budgetRepository
        self.categoryRepository = categoryRepository
        setupCurrentMonthYear()
    }

    // MARK: - Public Methods

    func fetchBudgets() {
        onLoading?(true)

        let result = budgetRepository.fetchAllBudgetsWithSpending(month: selectedMonth, year: selectedYear)

        onLoading?(false)

        switch result {
        case .success(let budgetsWithSpending):
            self.budgets = budgetsWithSpending.map { BudgetDisplayModel(budgetWithSpending: $0) }
            onBudgetsUpdated?()

        case .failure(let error):
            onError?(error)
        }
    }

    func deleteBudget(at index: Int) {
        guard index < budgets.count else { return }

        let budgetToDelete = budgets[index]
        // Need to get the original Budget object - this is a limitation of current approach
        // For now, we'll need to refetch

        let result = budgetRepository.fetchBudgets(month: selectedMonth, year: selectedYear)

        switch result {
        case .success(let fetchedBudgets):
            if let budget = fetchedBudgets.first(where: { $0.id == budgetToDelete.id }) {
                let deleteResult = budgetRepository.deleteBudget(budget)

                switch deleteResult {
                case .success:
                    budgets.remove(at: index)
                    onBudgetsUpdated?()
                case .failure(let error):
                    onError?(error)
                }
            }
        case .failure(let error):
            onError?(error)
        }
    }

    func navigateToPreviousMonth() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return
        }

        let prevComponents = calendar.dateComponents([.month, .year], from: previousMonthDate)
        selectedMonth = Int16(prevComponents.month ?? 1)
        selectedYear = Int16(prevComponents.year ?? 2025)

        fetchBudgets()
    }

    func navigateToNextMonth() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
            return
        }

        let nextComponents = calendar.dateComponents([.month, .year], from: nextMonthDate)
        let nextMonth = Int16(nextComponents.month ?? 1)
        let nextYear = Int16(nextComponents.year ?? 2025)

        // Don't allow navigating beyond current month
        if nextYear > currentYear || (nextYear == currentYear && nextMonth > currentMonth) {
            return
        }

        selectedMonth = nextMonth
        selectedYear = nextYear

        fetchBudgets()
    }

    func canNavigateToPreviousMonth() -> Bool {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return false
        }

        let prevComponents = calendar.dateComponents([.month, .year], from: previousMonthDate)
        let prevMonth = Int16(prevComponents.month ?? 1)
        let prevYear = Int16(prevComponents.year ?? 2025)

        // Check if previous month has budgets
        let result = budgetRepository.fetchBudgets(month: prevMonth, year: prevYear)
        if case .success(let budgets) = result {
            return !budgets.isEmpty
        }

        return false
    }

    func canNavigateToNextMonth() -> Bool {
        return !(selectedMonth == currentMonth && selectedYear == currentYear)
    }

    func getMonthYearString() -> String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let date = calendar.date(from: components) else { return "" }

        return DateFormatter.monthYear.string(from: date).capitalized
    }

    // MARK: - Private Methods

    private func setupCurrentMonthYear() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        currentMonth = Int16(components.month ?? 1)
        currentYear = Int16(components.year ?? 2025)
        selectedMonth = currentMonth
        selectedYear = currentYear
    }
}
