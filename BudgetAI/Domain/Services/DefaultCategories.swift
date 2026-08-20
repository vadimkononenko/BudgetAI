//
//  DefaultCategories.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

enum DefaultCategories {
    static let versions: [Int: [CategoryDraft]] = [
        1: expenseCategories + incomeCategories
    ]

    private static let expenseCategories: [CategoryDraft] = [
        CategoryDraft(name: "Їжа", colorHex: "#FF6B6B", icon: "🍔", type: "expense"),
        CategoryDraft(name: "Транспорт", colorHex: "#4ECDC4", icon: "🚗", type: "expense"),
        CategoryDraft(name: "Розваги", colorHex: "#FFE66D", icon: "🎮", type: "expense"),
        CategoryDraft(name: "Здоров'я", colorHex: "#95E1D3", icon: "💊", type: "expense"),
        CategoryDraft(name: "Покупки", colorHex: "#FF8B94", icon: "🛍️", type: "expense"),
        CategoryDraft(name: "Комунальні", colorHex: "#A8E6CF", icon: "🏠", type: "expense"),
        CategoryDraft(name: "Освіта", colorHex: "#FFDAC1", icon: "📚", type: "expense"),
        CategoryDraft(name: "Інше", colorHex: "#B5B5B5", icon: "📦", type: "expense")
    ]

    private static let incomeCategories: [CategoryDraft] = [
        CategoryDraft(name: "Зарплата", colorHex: "#00D9FF", icon: "💰", type: "income"),
        CategoryDraft(name: "Фріланс", colorHex: "#8AC4FF", icon: "💻", type: "income"),
        CategoryDraft(name: "Інвестиції", colorHex: "#B8E986", icon: "📈", type: "income"),
        CategoryDraft(name: "Подарунок", colorHex: "#FFABAB", icon: "🎁", type: "income"),
        CategoryDraft(name: "Інше", colorHex: "#D4D4D4", icon: "💵", type: "income")
    ]
}
