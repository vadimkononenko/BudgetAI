//
//  Localizable.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import Foundation

/// Provides localized strings for the application
enum L10n {

    // MARK: - Tab Bar

    enum TabBar {
        static let budgets = "Бюджети"
        static let transactions = "Транзакції"
        static let statistics = "Статистика"
        static let forecast = "Прогноз"
    }

    // MARK: - Budget Screen

    enum Budget {
        static let title = "Бюджети"
        static let addBudget = "Додати бюджет"
        static let noBudgets = "Немає бюджетів"
        static let createFirst = "Створіть свій перший бюджет"
        static let archive = "📦 Архів"
        static let spent = "Витрачено"
        static let remaining = "Залишилось"
        static let exceeded = "Перевищено"
        static let budgetAmount = "Сума бюджету"
        static let delete = "Видалити"
        static let cancel = "Скасувати"
        static let deleteBudgetTitle = "Видалити бюджет?"
        static let deleteBudgetMessage = "Ця дія незворотна"
    }

    // MARK: - Budget Detail

    enum BudgetDetail {
        static let statistics = "Статистика"
        static let transactions = "Транзакції"
        static let noTransactions = "Немає транзакцій"
        static let count = "Кількість"
        static let average = "Середнє"
        static let maximum = "Максимум"
        static let minimum = "Мінімум"
        static let addTransaction = "Додати транзакцію"
    }

    // MARK: - Transaction Screen

    enum Transaction {
        static let title = "Транзакції"
        static let newTransaction = "Нова транзакція"
        static let editTransaction = "Редагувати транзакцію"
        static let transactionDetails = "Деталі транзакції"
        static let noTransactions = "Немає транзакцій\nДодайте нову транзакцію, натиснувши +"
        static let amount = "Сума"
        static let description = "Опис"
        static let descriptionOptional = "Опис (необов'язково)"
        static let descriptionPlaceholder = "Додати опис..."
        static let date = "Дата:"
        static let category = "Категорія"
        static let selectCategory = "Виберіть категорію"
        static let type = "Тип"
        static let expense = "Витрата"
        static let income = "Дохід"
        static let save = "Зберегти"
        static let delete = "Видалити транзакцію"
        static let deleteTitle = "Видалити транзакцію?"
        static let deleteMessage = "Ця дія незворотна"
        static let cancel = "Скасувати"
        static let budget = "Бюджет"
        static let incomeGoal = "Ціль доходу"
        static let thisMonthInCategory = "Цього місяця в категорії"
        static let noData = "Немає даних"
        static let currencySymbol = "₴"
        static let aiClassified = "🤖"
    }

    // MARK: - Statistics Screen

    enum Statistics {
        static let title = "Статистика"
        static let income = "Дохід"
        static let expenses = "Витрати"
        static let balance = "Баланс"
        static let currentMonth = "Поточний місяць"
        static let currentYear = "Поточний рік"
        static let allTime = "Весь час"
        static let selectMonth = "Оберіть місяць"
        static let topCategories = "Топ 5 категорій витрат"
        static let allCategories = "Всі категорії витрат"
        static let showMore = "Показати всі"
        static let noData = "Немає даних для відображення"
        static let filterByCategories = "Фільтр за категоріями"
        static let clear = "Очистити"

        // Charts
        static let expenseDistribution = "Розподіл витрат"
        static let expenseTrend = "Тренд витрат з часом"
        static let monthComparison = "Порівняння місяців"
        static let averageIncome = "Сер. дохід"
        static let averageExpenses = "Сер. витрати"
        static let averageIndicators = "Середні показники"
    }

    // MARK: - Forecast Screen

    enum Forecast {
        static let title = "Прогноз"
        static let forecastByCategory = "Прогноз за категоріями"
        static let expectedSpending = "Очікувані витрати"
        static let noData = "Недостатньо даних для прогнозування"
        static let dataProgress = "Прогрес збору даних"
        static let startAddingTransactions = "Почніть додавати транзакції"
        static let collectingData = "Збираємо дані для прогнозування"
        static let enoughData = "Достатньо даних!"
        static let usingMLModel = "Використовується ML модель для точного прогнозування"
        static let usingSimplified = "⚠️ Використовується спрощений алгоритм прогнозування"
        static let monthsProgress = "%d з %d місяців"
        static let monthsRemaining = "Ще %d %@ до точного AI прогнозу"
        static let minMonthsRequired = "Для точного прогнозування потрібно мінімум %d місяці історії витрат"
        static let monthWord1 = "місяць"
        static let monthWord2 = "місяці"
        static let monthWord5 = "місяців"
        static let increase = "збільшення"
        static let decrease = "зменшення"
        static let stable = "стабільно"
    }

    // MARK: - Validation

    enum Validation {
        static let error = "Помилка валідації"
        static let amountRequired = "Сума обов'язкова"
        static let amountInvalid = "Невірний формат суми"
        static let amountPositive = "Сума повинна бути більше 0"
        static let categoryRequired = "Оберіть категорію"
        static let descriptionTooLong = "Опис занадто довгий (макс. 500 символів)"
        static let ok = "OK"
    }

    // MARK: - Common

    enum Common {
        static let add = "Додати"
        static let edit = "Редагувати"
        static let delete = "Видалити"
        static let cancel = "Скасувати"
        static let save = "Зберегти"
        static let done = "Готово"
        static let close = "Закрити"
        static let ok = "OK"
        static let error = "Помилка"
        static let success = "Успішно"
        static let loading = "Завантаження..."
        static let noData = "Немає даних"
    }

    // MARK: - Helpers

    /// Returns the correct Ukrainian plural form for months
    /// - Parameter count: Number of months
    /// - Returns: Localized month word
    static func monthWord(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100

        if remainder10 == 1 && remainder100 != 11 {
            return Forecast.monthWord1
        } else if remainder10 >= 2 && remainder10 <= 4 && (remainder100 < 10 || remainder100 >= 20) {
            return Forecast.monthWord2
        } else {
            return Forecast.monthWord5
        }
    }
}
