//
//  TransactionCategorizationService.swift
//  BudgetAI
//
//  Created by AI on 21.10.2025.
//

import Foundation

/// Протокол для сервісу автоматичної категоризації транзакцій
protocol TransactionCategorizationService {
    /// Передбачає категорію транзакції на основі опису
    /// - Parameters:
    ///   - description: Опис транзакції
    ///   - type: Тип транзакції (expense або income)
    /// - Returns: Назва категорії або nil, якщо не вдалося передбачити
    func predictCategory(for description: String, type: String) -> String?

    /// Передбачає категорію з рівнем впевненості
    /// - Parameters:
    ///   - description: Опис транзакції
    ///   - type: Тип транзакції (expense або income)
    /// - Returns: Кортеж з назвою категорії та впевненістю (0-1) або nil
    func predictCategoryWithConfidence(for description: String, type: String) -> (category: String, confidence: Double)?
}
