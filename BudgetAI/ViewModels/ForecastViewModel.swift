//
//  ForecastViewModel.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation

final class ForecastViewModel {

    // MARK: - Properties

    private let forecastService: ExpenseForecastService
    private let dataAggregator: ExpenseDataAggregator
    private(set) var forecasts: [CategoryForecast] = []
    private(set) var errorMessage: String?
    private(set) var hasEnoughData: Bool = false
    private(set) var monthsOfData: Int = 0
    private(set) var isBasicForecast: Bool = false

    var onForecastsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?

    // MARK: - Computed Properties

    var totalPredictedExpense: Double {
        forecasts.reduce(0) { $0 + $1.predictedAmount }
    }

    var nextMonthName: String {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: nextMonth).capitalized
    }

    var isEmpty: Bool {
        return forecasts.isEmpty
    }

    // MARK: - Initialization

    init(forecastService: ExpenseForecastService, dataAggregator: ExpenseDataAggregator) {
        self.forecastService = forecastService
        self.dataAggregator = dataAggregator
    }

    // MARK: - Public Methods

    func loadForecasts() {
        monthsOfData = dataAggregator.getMonthsOfDataCount()

        let result = forecastService.generateForecastForNextMonth()

        switch result {
        case .success(let forecasts):
            self.forecasts = forecasts
            self.hasEnoughData = monthsOfData >= 3
            self.isBasicForecast = forecasts.first?.isBasicForecast ?? false
            self.errorMessage = nil
            onForecastsUpdated?()

        case .failure(let error):
            self.forecasts = []
            self.hasEnoughData = false
            self.isBasicForecast = false

            switch error {
            case .notEnoughData:
                self.errorMessage = "Недостатньо даних для прогнозування. Додайте більше транзакцій."
            case .modelError(let message):
                self.errorMessage = "Помилка моделі: \(message)"
            case .dataAggregationError:
                self.errorMessage = "Помилка обробки даних. Спробуйте пізніше."
            }

            onError?(errorMessage ?? "Невідома помилка")
        }
    }

    func getForecast(at index: Int) -> CategoryForecast? {
        guard index < forecasts.count else { return nil }
        return forecasts[index]
    }

    func numberOfForecasts() -> Int {
        return forecasts.count
    }

    // MARK: - Formatting Helpers

    func formattedAmount(_ amount: Double) -> String {
        return CurrencyFormatter.shared.format(amount)
    }

    func confidenceText(for confidence: Double) -> String {
        if confidence >= 0.8 {
            return "Висока впевненість"
        } else if confidence >= 0.6 {
            return "Середня впевненість"
        } else {
            return "Низька впевненість"
        }
    }

    func confidenceColor(for confidence: Double) -> String {
        if confidence >= 0.8 {
            return "#4CAF50" // Green
        } else if confidence >= 0.6 {
            return "#FF9800" // Orange
        } else {
            return "#F44336" // Red
        }
    }
}
