//
//  MLTransactionCategorizationService.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation
import CoreML

/// Implementation of transaction categorization service using CoreML
/// This service uses a trained machine learning model to predict transaction categories based on descriptions
class MLTransactionCategorizationService: TransactionCategorizationService {

    // MARK: - Properties

    /// The CoreML transaction category classifier model
    let model: TransactionCategoryClassifier

    /// Minimum confidence threshold for accepting predictions (0-1)
    private let minimumConfidence: Double

    // MARK: - Initialization

    /// Initializes the service with ML model
    /// - Parameter minimumConfidence: Minimum confidence level to accept prediction (0-1). Default is 0.5
    /// - Throws: Error if the ML model fails to load
    init(minimumConfidence: Double = 0.5) throws {
        self.model = try TransactionCategoryClassifier(configuration: MLModelConfiguration())
        self.minimumConfidence = minimumConfidence
    }

    // MARK: - TransactionCategorizationService

    /// Predicts transaction category based on description
    /// - Parameters:
    ///   - description: Transaction description text
    ///   - type: Transaction type (expense or income)
    /// - Returns: Predicted category name or nil if prediction failed
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

    /// Predicts transaction category with confidence level
    /// - Parameters:
    ///   - description: Transaction description text
    ///   - type: Transaction type (expense or income)
    /// - Returns: Tuple containing category name and confidence (0-1), or nil if prediction failed or confidence is below threshold
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

    /// Gets all possible categories with their probabilities
    /// - Parameters:
    ///   - description: Transaction description text
    ///   - type: Transaction type (expense or income). Default is "expense"
    /// - Returns: Dictionary mapping category names to their probabilities, or nil if prediction failed
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

    /// Gets top N categories with highest probabilities
    /// - Parameters:
    ///   - description: Transaction description text
    ///   - type: Transaction type (expense or income). Default is "expense"
    ///   - limit: Maximum number of categories to return. Default is 3
    /// - Returns: Array of tuples (category, confidence) sorted by confidence in descending order, or nil if prediction failed
    func getTopPredictions(for description: String, type: String = "expense", limit: Int = 3) -> [(category: String, confidence: Double)]? {
        guard let allPredictions = getAllPredictions(for: description, type: type) else {
            return nil
        }

        let sorted = allPredictions.sorted { $0.value > $1.value }
        let topPredictions = Array(sorted.prefix(limit))

        return topPredictions.map { (category: $0.key, confidence: $0.value) }
    }
}
