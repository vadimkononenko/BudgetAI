//
//  DefaultData.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

struct CategoryData {
    let name: String
    let colorHex: String
    let icon: String
    let type: String
}

final class DefaultData {

    static let expenseCategories: [CategoryData] = [
        CategoryData(name: "Їжа", colorHex: "#FF6B6B", icon: "🍔", type: "expense"),
        CategoryData(name: "Транспорт", colorHex: "#4ECDC4", icon: "🚗", type: "expense"),
        CategoryData(name: "Розваги", colorHex: "#FFE66D", icon: "🎮", type: "expense"),
        CategoryData(name: "Здоров'я", colorHex: "#95E1D3", icon: "💊", type: "expense"),
        CategoryData(name: "Покупки", colorHex: "#FF8B94", icon: "🛍️", type: "expense"),
        CategoryData(name: "Комунальні", colorHex: "#A8E6CF", icon: "🏠", type: "expense"),
        CategoryData(name: "Освіта", colorHex: "#FFDAC1", icon: "📚", type: "expense"),
        CategoryData(name: "Інше", colorHex: "#B5B5B5", icon: "📦", type: "expense")
    ]

    static let incomeCategories: [CategoryData] = [
        CategoryData(name: "Зарплата", colorHex: "#00D9FF", icon: "💰", type: "income"),
        CategoryData(name: "Фріланс", colorHex: "#8AC4FF", icon: "💻", type: "income"),
        CategoryData(name: "Інвестиції", colorHex: "#B8E986", icon: "📈", type: "income"),
        CategoryData(name: "Подарунок", colorHex: "#FFABAB", icon: "🎁", type: "income"),
        CategoryData(name: "Інше", colorHex: "#D4D4D4", icon: "💵", type: "income")
    ]

    static func initializeDefaultCategories() {
        let repository = CoreDataCategoryRepository()

        let existingResult = repository.fetchAllCategories()

        switch existingResult {
        case .success(let existingCategories):
            guard existingCategories.isEmpty else {
                return
            }

            // Create expense categories
            for categoryData in expenseCategories {
                _ = repository.createCategory(
                    name: categoryData.name,
                    colorHex: categoryData.colorHex,
                    icon: categoryData.icon,
                    type: categoryData.type
                )
            }

            // Create income categories
            for categoryData in incomeCategories {
                _ = repository.createCategory(
                    name: categoryData.name,
                    colorHex: categoryData.colorHex,
                    icon: categoryData.icon,
                    type: categoryData.type
                )
            }

            print("✅ Default categories initialized successfully")

        case .failure(let error):
            print("❌ Failed to initialize default categories: \(error.localizedDescription)")
        }
    }
}
