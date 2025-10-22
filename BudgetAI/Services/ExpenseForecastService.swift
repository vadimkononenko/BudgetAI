//
//  ExpenseForecastService.swift
//  BudgetAI
//
//  Created by Claude on 21.10.2025.
//

import Foundation
import CoreML

struct CategoryForecast {
    let categoryName: String
    let predictedAmount: Double
    let confidence: Double // 0.0 - 1.0
    let historicalAverage: Double
    let isBasicForecast: Bool // true якщо використано простий алгоритм (не ML)
}

enum ForecastError: Error {
    case notEnoughData
    case modelError(String)
    case dataAggregationError
}

final class ExpenseForecastService {

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let dataAggregator: ExpenseDataAggregator
    private var model: ExpenseForecastModel?

    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.dataAggregator = ExpenseDataAggregator(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository
        )

        // Завантажуємо модель
        loadModel()
    }

    // MARK: - Public Methods

    /// Генерує прогноз витрат на наступний місяць для всіх категорій
    func generateForecastForNextMonth() -> Result<[CategoryForecast], ForecastError> {
        let monthsCount = dataAggregator.getMonthsOfDataCount()

        // Якщо зовсім немає даних
        guard monthsCount > 0 else {
            return .failure(.notEnoughData)
        }

        // Якщо менше 3 місяців - використовуємо простий алгоритм
        if monthsCount < 3 {
            return generateBasicForecast()
        }

        // Перевіряємо чи модель завантажена
        guard let model = model else {
            return .failure(.modelError("ML model not loaded"))
        }

        // Отримуємо історичні дані
        guard case .success(let historicalData) = dataAggregator.aggregateMonthlyExpenses() else {
            return .failure(.dataAggregationError)
        }

        // Визначаємо наступний місяць
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) else {
            return .failure(.modelError("Failed to calculate next month"))
        }

        let components = calendar.dateComponents([.year, .month], from: nextMonth)
        guard let targetYear = components.year, let targetMonth = components.month else {
            return .failure(.modelError("Failed to extract year/month"))
        }

        // Отримуємо унікальні категорії
        let uniqueCategories = Set(historicalData.map { $0.categoryName })

        var forecasts: [CategoryForecast] = []

        for categoryName in uniqueCategories {
            // Розраховуємо середнє за останні 3 місяці для цієї категорії
            let averageLastThreeMonths = calculateAverageLastThreeMonths(
                categoryName: categoryName,
                historicalData: historicalData
            )

            let season = getSeason(month: targetMonth)

            // Генеруємо прогноз за допомогою моделі
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

                // Розраховуємо confidence на основі відхилення від історичного середнього
                let confidence = calculateConfidence(
                    predicted: predictedAmount,
                    historical: averageLastThreeMonths
                )

                let forecast = CategoryForecast(
                    categoryName: categoryName,
                    predictedAmount: max(0, predictedAmount), // Не може бути від'ємним
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

        // Сортуємо за прогнозованою сумою (від більшої до меншої)
        forecasts.sort { $0.predictedAmount > $1.predictedAmount }

        return .success(forecasts)
    }

    /// Генерує прогноз для конкретної категорії
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
        // Фільтруємо дані для цієї категорії
        let categoryData = historicalData.filter { $0.categoryName == categoryName }

        // Сортуємо за датою (найновіші спочатку)
        let sortedData = categoryData.sorted { (data1, data2) -> Bool in
            if data1.year != data2.year {
                return data1.year > data2.year
            }
            return data1.month > data2.month
        }

        // Беремо останні 3 місяці
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

        // Чим менше відхилення від історичного середнього, тим вища впевненість
        let deviation = abs(predicted - historical) / historical

        // Конвертуємо девіацію в confidence (0.0 - 1.0)
        // 0% відхилення = 1.0 confidence
        // 50%+ відхилення = 0.5 confidence
        let confidence = max(0.5, 1.0 - (deviation * 0.5))

        return confidence
    }

    /// Генерує базовий прогноз на основі простого середнього (для користувачів з 1-2 місяцями даних)
    private func generateBasicForecast() -> Result<[CategoryForecast], ForecastError> {
        // Отримуємо історичні дані
        guard case .success(let historicalData) = dataAggregator.aggregateMonthlyExpenses() else {
            return .failure(.dataAggregationError)
        }

        guard !historicalData.isEmpty else {
            return .failure(.notEnoughData)
        }

        // Отримуємо унікальні категорії
        let uniqueCategories = Set(historicalData.map { $0.categoryName })

        var forecasts: [CategoryForecast] = []

        for categoryName in uniqueCategories {
            // Фільтруємо дані для цієї категорії
            let categoryData = historicalData.filter { $0.categoryName == categoryName }

            guard !categoryData.isEmpty else { continue }

            // Розраховуємо просте середнє всіх наявних місяців
            let average = categoryData.reduce(0.0) { $0 + $1.totalAmount } / Double(categoryData.count)

            // Для базового прогнозу впевненість залежить від кількості місяців
            let monthsCount = dataAggregator.getMonthsOfDataCount()
            let baseConfidence: Double
            switch monthsCount {
            case 1:
                baseConfidence = 0.3 // Низька впевненість - тільки 1 місяць
            case 2:
                baseConfidence = 0.5 // Середня впевненість - 2 місяці
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

        // Сортуємо за прогнозованою сумою
        forecasts.sort { $0.predictedAmount > $1.predictedAmount }

        return .success(forecasts)
    }
}
