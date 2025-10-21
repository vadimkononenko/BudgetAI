#!/usr/bin/env swift

import Foundation

// Генератор тестових даних для тренування ML моделі прогнозування витрат
// Цей скрипт створює CSV файл з історичними даними витрат

struct ExpenseRecord {
    let year: Int
    let month: Int
    let category: String
    let averageLastThreeMonths: Double
    let season: Int
    let totalAmount: Double
}

let categories = [
    "Їжа",
    "Транспорт",
    "Розваги",
    "Здоров'я",
    "Комунальні послуги",
    "Одяг",
    "Подорожі"
]

// Базові витрати для кожної категорії (середні на місяць)
let baseCosts: [String: Double] = [
    "Їжа": 5000,
    "Транспорт": 2000,
    "Розваги": 1500,
    "Здоров'я": 1000,
    "Комунальні послуги": 3000,
    "Одяг": 1200,
    "Подорожі": 2500
]

// Сезонні коефіцієнти (1 = Winter, 2 = Spring, 3 = Summer, 4 = Fall)
let seasonalMultipliers: [String: [Int: Double]] = [
    "Їжа": [1: 1.1, 2: 1.0, 3: 0.95, 4: 1.05],
    "Транспорт": [1: 0.9, 2: 1.0, 3: 1.2, 4: 1.0],
    "Розваги": [1: 1.15, 2: 1.0, 3: 1.3, 4: 1.0],
    "Здоров'я": [1: 1.2, 2: 0.9, 3: 0.85, 4: 1.05],
    "Комунальні послуги": [1: 1.5, 2: 1.0, 3: 0.7, 4: 1.1],
    "Одяг": [1: 1.3, 2: 1.1, 3: 0.8, 4: 1.2],
    "Подорожі": [1: 0.8, 2: 1.1, 3: 1.5, 4: 1.0]
]

func getSeason(month: Int) -> Int {
    switch month {
    case 12, 1, 2: return 1 // Winter
    case 3, 4, 5: return 2  // Spring
    case 6, 7, 8: return 3  // Summer
    case 9, 10, 11: return 4 // Fall
    default: return 1
    }
}

func calculateAverageLastThreeMonths(
    records: [ExpenseRecord],
    category: String,
    currentYear: Int,
    currentMonth: Int
) -> Double {
    var amounts: [Double] = []

    for i in 1...3 {
        var targetMonth = currentMonth - i
        var targetYear = currentYear

        if targetMonth <= 0 {
            targetMonth += 12
            targetYear -= 1
        }

        if let record = records.first(where: { $0.year == targetYear && $0.month == targetMonth && $0.category == category }) {
            amounts.append(record.totalAmount)
        }
    }

    guard !amounts.isEmpty else { return 0.0 }
    return amounts.reduce(0, +) / Double(amounts.count)
}

// Генеруємо дані за останні 24 місяці
var records: [ExpenseRecord] = []
let endDate = Date()
let calendar = Calendar.current

for monthsAgo in (0..<24).reversed() {
    guard let date = calendar.date(byAdding: .month, value: -monthsAgo, to: endDate) else { continue }

    let components = calendar.dateComponents([.year, .month], from: date)
    guard let year = components.year, let month = components.month else { continue }

    let season = getSeason(month: month)

    for category in categories {
        guard let baseCost = baseCosts[category],
              let seasonalMultiplier = seasonalMultipliers[category]?[season] else {
            continue
        }

        // Додаємо випадковість ±20%
        let randomFactor = Double.random(in: 0.8...1.2)

        // Додаємо тренд зростання витрат (приблизно 2% на рік)
        let yearsSinceStart = Double(24 - monthsAgo) / 12.0
        let trendFactor = 1.0 + (yearsSinceStart * 0.02)

        let totalAmount = baseCost * seasonalMultiplier * randomFactor * trendFactor

        // Для перших 3 місяців середнє буде 0 або базоване на неповних даних
        let average = calculateAverageLastThreeMonths(
            records: records,
            category: category,
            currentYear: year,
            currentMonth: month
        )

        let record = ExpenseRecord(
            year: year,
            month: month,
            category: category,
            averageLastThreeMonths: average,
            season: season,
            totalAmount: totalAmount
        )

        records.append(record)
    }
}

// Записуємо у CSV файл
var csvString = "year,month,category,averageLastThreeMonths,season,totalAmount\n"

for record in records {
    csvString += "\(record.year),\(record.month),\(record.category),\(record.averageLastThreeMonths),\(record.season),\(record.totalAmount)\n"
}

// Зберігаємо файл
let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("expense_training_data.csv")

do {
    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    print("✅ Training data generated successfully!")
    print("📁 File saved to: \(fileURL.path)")
    print("📊 Total records: \(records.count)")
    print("\nYou can now use this CSV file in CreateML to train your Tabular Regressor model.")
} catch {
    print("❌ Error writing file: \(error.localizedDescription)")
}
