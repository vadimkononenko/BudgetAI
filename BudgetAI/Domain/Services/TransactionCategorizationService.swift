//
//  TransactionCategorizationService.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import Foundation

/// Protocol for automatic transaction categorization service
protocol TransactionCategorizationService {
    /// Predicts transaction category based on description
    /// - Parameters:
    ///   - description: Transaction description
    ///   - type: Transaction type (expense or income)
    /// - Returns: Category name or nil if prediction failed
    func predictCategory(for description: String, type: String) -> String?

    /// Predicts category with confidence level
    /// - Parameters:
    ///   - description: Transaction description
    ///   - type: Transaction type (expense or income)
    /// - Returns: Tuple with category name and confidence (0-1) or nil
    func predictCategoryWithConfidence(for description: String, type: String) -> (category: String, confidence: Double)?
}
