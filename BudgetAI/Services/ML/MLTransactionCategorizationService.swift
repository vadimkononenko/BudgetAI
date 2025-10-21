//
//  MLTransactionCategorizationService.swift
//  BudgetAI
//
//  Created by AI on 21.10.2025.
//

import Foundation
import CoreML

/// Реалізація сервісу категоризації транзакцій з використанням CoreML
class MLTransactionCategorizationService: TransactionCategorizationService {

    // MARK: - Properties

    let model: TransactionCategoryClassifier
    private let minimumConfidence: Double

    // MARK: - Initialization

    /// Ініціалізує сервіс з ML моделлю
    /// - Parameter minimumConfidence: Мінімальний рівень впевненості для прийняття прогнозу (0-1). За замовчуванням 0.5
    init(minimumConfidence: Double = 0.5) throws {
        self.model = try TransactionCategoryClassifier(configuration: MLModelConfiguration())
        self.minimumConfidence = minimumConfidence
    }

    // MARK: - TransactionCategorizationService

    func predictCategory(for description: String, type: String) -> String? {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let typedText = "\(type): \(description)"

        do {
            let prediction = try model.prediction(text: typedText)
            return prediction.label
        } catch {
            return nil
        }
    }

    func predictCategoryWithConfidence(for description: String, type: String) -> (category: String, confidence: Double)? {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let typedText = "\(type): \(description)"

        do {
            let input = TransactionCategoryClassifierInput(text: typedText)
            let output = try model.model.prediction(from: input)

            guard let labelFeature = output.featureValue(for: "label") else {
                return nil
            }
            let category = labelFeature.stringValue

            if let probabilitiesFeature = output.featureValue(for: "labelProbability"),
               let probabilities = probabilitiesFeature.dictionaryValue as? [String: Double],
               let confidence = probabilities[category],
               confidence >= minimumConfidence {
                return (category: category, confidence: confidence)
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Helper Methods

    /// Отримує всі можливі категорії з їх ймовірностями
    /// - Parameter description: Опис транзакції
    /// - Parameter type: Тип транзакції (expense або income)
    /// - Returns: Словник категорій з ймовірностями
    func getAllPredictions(for description: String, type: String = "expense") -> [String: Double]? {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let typedText = "\(type): \(description)"

        do {
            let input = TransactionCategoryClassifierInput(text: typedText)
            let output = try model.model.prediction(from: input)

            if let probabilitiesFeature = output.featureValue(for: "labelProbability"),
               let probabilities = probabilitiesFeature.dictionaryValue as? [String: Double] {
                return probabilities
            }

            return nil
        } catch {
            return nil
        }
    }

    /// Отримує топ N категорій з найвищими ймовірностями
    /// - Parameters:
    ///   - description: Опис транзакції
    ///   - type: Тип транзакції (expense або income)
    ///   - limit: Кількість категорій для повернення
    /// - Returns: Масив кортежів (категорія, впевненість) відсортованих за впевненістю
    func getTopPredictions(for description: String, type: String = "expense", limit: Int = 3) -> [(category: String, confidence: Double)]? {
        guard let allPredictions = getAllPredictions(for: description, type: type) else {
            return nil
        }

        let sorted = allPredictions.sorted { $0.value > $1.value }
        let topPredictions = Array(sorted.prefix(limit))

        return topPredictions.map { (category: $0.key, confidence: $0.value) }
    }
}
