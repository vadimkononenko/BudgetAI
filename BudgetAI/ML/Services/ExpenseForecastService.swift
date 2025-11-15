//
//  ExpenseForecastService.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation
import CoreML

/// Represents a forecast for a specific expense category
struct CategoryForecast {
    /// Name of the category
    let categoryName: String

    /// Predicted expense amount for the category
    let predictedAmount: Double

    /// Confidence level of the prediction (0.0 - 1.0)
    let confidence: Double

    /// Historical average expense for this category
    let historicalAverage: Double

    /// Indicates if simple algorithm was used instead of ML model
    let isBasicForecast: Bool
}

/// Errors that can occur during expense forecasting
enum ForecastError: Error {
    /// Insufficient historical data for forecasting
    case notEnoughData

    /// ML model related error
    case modelError(String)

    /// Error aggregating expense data
    case dataAggregationError
}

/// Service for forecasting future expenses using machine learning
/// Uses CoreML model to predict expenses based on historical data, seasonal patterns, and trends
final class ExpenseForecastService {

    /// Repository for accessing transaction data
    private let transactionRepository: TransactionRepository

    /// Repository for accessing category data
    private let categoryRepository: CategoryRepository

    /// Aggregator for preparing expense data
    private let dataAggregator: ExpenseDataAggregator

    /// CoreML expense forecast model
    private var model: ExpenseForecastModel?

    /// Initializes the expense forecast service
    /// - Parameters:
    ///   - transactionRepository: Repository for transaction data access
    ///   - categoryRepository: Repository for category data access
    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.dataAggregator = ExpenseDataAggregator(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository
        )

        // Load the model
        loadModel()
    }

    // MARK: - Public Methods

    /// Generates expense forecast for next month for all categories
    /// - Returns: Result containing array of category forecasts or error
    /// - Note: Uses ML model if 3+ months of data available, otherwise uses simple averaging
    func generateForecastForNextMonth() -> Result<[CategoryForecast], ForecastError> {
        let monthsCount = dataAggregator.getMonthsOfDataCount()

        // If there's no data at all
        guard monthsCount > 0 else {
            return .failure(.notEnoughData)
        }

        // If less than 3 months - use simple algorithm
        if monthsCount < 3 {
            return generateBasicForecast()
        }

        // Check if model is loaded
        guard let model = model else {
            return .failure(.modelError("ML model not loaded"))
        }

        // Get historical data
        guard case .success(let historicalData) = dataAggregator.aggregateMonthlyExpenses() else {
            return .failure(.dataAggregationError)
        }

        // Determine next month
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) else {
            return .failure(.modelError("Failed to calculate next month"))
        }

        let components = calendar.dateComponents([.year, .month], from: nextMonth)
        guard let targetYear = components.year, let targetMonth = components.month else {
            return .failure(.modelError("Failed to extract year/month"))
        }

        // Get unique categories
        let uniqueCategories = Set(historicalData.map { $0.categoryName })

        var forecasts: [CategoryForecast] = []

        for categoryName in uniqueCategories {
            // Calculate average for last 3 months for this category
            let averageLastThreeMonths = calculateAverageLastThreeMonths(
                categoryName: categoryName,
                historicalData: historicalData
            )

            let season = getSeason(month: targetMonth)

            // Generate forecast using the model
            do {
                let input = ExpenseForecastModelInput(
                    year: Int64(targetYear),
                    month: Int64(targetMonth),
                    category: categoryName,
                    averageLastThreeMonths: averageLastThreeMonths,
                    season: Int64(season)
                )

                let prediction = try model.prediction(input: input)
                let predictedAmount = prediction.totalAmount

                // Calculate confidence based on deviation from historical average
                let confidence = calculateConfidence(
                    predicted: predictedAmount,
                    historical: averageLastThreeMonths
                )

                let forecast = CategoryForecast(
                    categoryName: categoryName,
                    predictedAmount: max(0, predictedAmount), // Cannot be negative
                    confidence: confidence,
                    historicalAverage: averageLastThreeMonths,
                    isBasicForecast: false
                )

                forecasts.append(forecast)

            } catch {
                print("Error predicting for category \(categoryName): \(error)")
                continue
            }
        }

        // Sort by predicted amount (from highest to lowest)
        forecasts.sort { $0.predictedAmount > $1.predictedAmount }

        return .success(forecasts)
    }

    /// Generates forecast for specific category
    /// - Parameter categoryName: Name of the category to forecast
    /// - Returns: Result containing category forecast or error
    func generateForecast(for categoryName: String) -> Result<CategoryForecast, ForecastError> {
        let allForecasts = generateForecastForNextMonth()

        switch allForecasts {
        case .success(let forecasts):
            if let forecast = forecasts.first(where: { $0.categoryName == categoryName }) {
                return .success(forecast)
            } else {
                return .failure(.notEnoughData)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Helpers

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            self.model = try ExpenseForecastModel(configuration: config)
        } catch {
            print("Failed to load ML model: \(error)")
        }
    }

    private func calculateAverageLastThreeMonths(
        categoryName: String,
        historicalData: [MonthlyExpenseData]
    ) -> Double {
        // Filter data for this category
        let categoryData = historicalData.filter { $0.categoryName == categoryName }

        // Sort by date (newest first)
        let sortedData = categoryData.sorted { (data1, data2) -> Bool in
            if data1.year != data2.year {
                return data1.year > data2.year
            }
            return data1.month > data2.month
        }

        // Take last 3 months
        let lastThree = Array(sortedData.prefix(3))

        guard !lastThree.isEmpty else { return 0.0 }

        let sum = lastThree.reduce(0.0) { $0 + $1.totalAmount }
        return sum / Double(lastThree.count)
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

    private func calculateConfidence(predicted: Double, historical: Double) -> Double {
        guard historical > 0 else { return 0.5 }

        // The smaller the deviation from historical average, the higher the confidence
        let deviation = abs(predicted - historical) / historical

        // Convert deviation to confidence (0.0 - 1.0)
        // 0% deviation = 1.0 confidence
        // 50%+ deviation = 0.5 confidence
        let confidence = max(0.5, 1.0 - (deviation * 0.5))

        return confidence
    }

    /// Generates basic forecast based on simple average (for users with 1-2 months of data)
    private func generateBasicForecast() -> Result<[CategoryForecast], ForecastError> {
        // Get historical data
        guard case .success(let historicalData) = dataAggregator.aggregateMonthlyExpenses() else {
            return .failure(.dataAggregationError)
        }

        guard !historicalData.isEmpty else {
            return .failure(.notEnoughData)
        }

        // Get unique categories
        let uniqueCategories = Set(historicalData.map { $0.categoryName })

        var forecasts: [CategoryForecast] = []

        for categoryName in uniqueCategories {
            // Filter data for this category
            let categoryData = historicalData.filter { $0.categoryName == categoryName }

            guard !categoryData.isEmpty else { continue }

            // Calculate simple average of all available months
            let average = categoryData.reduce(0.0) { $0 + $1.totalAmount } / Double(categoryData.count)

            // For basic forecast, confidence depends on number of months
            let monthsCount = dataAggregator.getMonthsOfDataCount()
            let baseConfidence: Double
            switch monthsCount {
            case 1:
                baseConfidence = 0.3 // Low confidence - only 1 month
            case 2:
                baseConfidence = 0.5 // Medium confidence - 2 months
            default:
                baseConfidence = 0.6
            }

            let forecast = CategoryForecast(
                categoryName: categoryName,
                predictedAmount: max(0, average),
                confidence: baseConfidence,
                historicalAverage: average,
                isBasicForecast: true
            )

            forecasts.append(forecast)
        }

        // Sort by predicted amount
        forecasts.sort { $0.predictedAmount > $1.predictedAmount }

        return .success(forecasts)
    }
}
