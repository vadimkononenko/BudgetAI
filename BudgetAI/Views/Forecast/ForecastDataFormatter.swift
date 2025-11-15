//
//  ForecastDataFormatter.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import Foundation
import UIKit

/// Handles all data formatting and preparation for the forecast view
/// Responsible for transforming raw data into display-ready strings and values
final class ForecastDataFormatter {

    // MARK: - Properties

    /// View model providing forecast data
    private let viewModel: ForecastViewModel

    /// Maps category names to their full category objects
    private var categoriesMap: [String: Category] = [:]

    /// Repository for fetching category data
    private let categoryRepository: CategoryRepository

    // MARK: - Initialization

    /// Initializes the formatter with required dependencies
    /// - Parameters:
    ///   - viewModel: The forecast view model containing data
    ///   - categoryRepository: Repository for accessing category data
    init(viewModel: ForecastViewModel, categoryRepository: CategoryRepository) {
        self.viewModel = viewModel
        self.categoryRepository = categoryRepository
    }

    // MARK: - Public Methods

    /// Loads all categories and creates a mapping for quick access
    /// Should be called once during view controller initialization
    func loadCategories() {
        let result = categoryRepository.fetchAllCategories()

        switch result {
        case .success(let categories):
            categoriesMap = categories.reduce(into: [String: Category]()) { result, category in
                if let name = category.name {
                    result[name] = category
                }
            }
        case .failure(let error):
            print("Failed to load categories: \(error)")
        }
    }

    /// Formats the next month name for display
    /// - Returns: Localized month name string (e.g., "November 2025")
    func getFormattedMonthName() -> String {
        return viewModel.nextMonthName
    }

    /// Formats the total predicted expense amount
    /// - Returns: Currency-formatted string (e.g., "$1,234.56")
    func getFormattedTotalAmount() -> String {
        let totalAmount = viewModel.totalPredictedExpense
        return viewModel.formattedAmount(totalAmount)
    }

    /// Gets the icon for a specific category
    /// - Parameter categoryName: The name of the category
    /// - Returns: Emoji icon string, defaults to "💰" if not found
    func getCategoryIcon(for categoryName: String) -> String {
        return categoriesMap[categoryName]?.icon ?? "💰"
    }

    /// Checks if the forecast data is empty
    /// - Returns: True if no forecast data is available
    func isEmpty() -> Bool {
        return viewModel.isEmpty
    }

    /// Gets the error message if available
    /// - Returns: Error message string or nil
    func getErrorMessage() -> String? {
        return viewModel.errorMessage
    }

    /// Gets the number of months of historical data available
    /// - Returns: Count of months with data
    func getMonthsOfData() -> Int {
        return viewModel.monthsOfData
    }

    /// Checks if the forecast is using basic (simplified) algorithm
    /// - Returns: True if using basic forecast due to insufficient data
    func isBasicForecast() -> Bool {
        return viewModel.isBasicForecast
    }

    /// Gets the subtitle text for the header
    /// - Returns: Appropriate subtitle based on forecast status
    func getSubtitleText() -> String {
        if viewModel.isBasicForecast && !viewModel.isEmpty {
            return "Спрощений прогноз (недостатньо даних для ШІ)"
        } else {
            return "Прогноз витрат на основі штучного інтелекту"
        }
    }

    /// Gets the subtitle text color
    /// - Returns: Appropriate color based on forecast status
    func getSubtitleColor() -> UIColor {
        return (viewModel.isBasicForecast && !viewModel.isEmpty) ? .systemOrange : .secondaryLabel
    }

    /// Gets the number of forecast items to display
    /// - Returns: Count of forecast items
    func getNumberOfForecasts() -> Int {
        return viewModel.numberOfForecasts()
    }

    /// Gets a specific forecast item
    /// - Parameter index: The index of the forecast item
    /// - Returns: CategoryForecast object or nil if index is invalid
    func getForecast(at index: Int) -> CategoryForecast? {
        return viewModel.getForecast(at: index)
    }

    /// Gets the empty state message
    /// - Returns: Appropriate message based on available data
    func getEmptyStateMessage() -> String {
        if let errorMessage = viewModel.errorMessage {
            return errorMessage
        }
        return "Немає даних доступних для прогнозування"
    }

    /// Checks if data progress view should be shown
    /// - Returns: True if there is some data but less than required for full AI forecast
    func shouldShowDataProgress() -> Bool {
        return viewModel.monthsOfData > 0
    }

    /// Gets the section header title
    /// - Returns: Section title or nil if empty
    func getSectionHeaderTitle() -> String? {
        return viewModel.isEmpty ? nil : "Прогноз по категоріям"
    }
}

