#!/usr/bin/env swift

import Foundation
import CreateML
import TabularData

print("🚀 Тренування РОЗШИРЕНОЇ ML моделі")
print("════════════════════════════════════════\n")

let currentDirectory = FileManager.default.currentDirectoryPath
let scriptDirectory = URL(fileURLWithPath: currentDirectory)
let csvPath = scriptDirectory.appendingPathComponent("transaction_training_data_rich.csv")

print("📂 Робоча директорія: \(currentDirectory)")
print("📂 CSV: \(csvPath.path)\n")

do {
    guard FileManager.default.fileExists(atPath: csvPath.path) else {
        print("❌ Файл не знайдено!")
        exit(1)
    }

    print("📥 Завантаження даних...")
    let dataFrame = try DataFrame(contentsOfCSVFile: csvPath)

    print("✅ Завантажено \(dataFrame.rows.count) прикладів")
    print("📊 Колонки: \(dataFrame.columns.map { $0.name })\n")

    // Підрахунок категорій
    var categoryCount: [String: Int] = [:]
    var expenseCount = 0
    var incomeCount = 0

    for row in dataFrame.rows {
        if let label = row["label", String.self] {
            categoryCount[label, default: 0] += 1
        }
        if let text = row["text", String.self] {
            if text.hasPrefix("expense:") {
                expenseCount += 1
            } else if text.hasPrefix("income:") {
                incomeCount += 1
            }
        }
    }

    print("📊 Розподіл по типах:")
    print("  • expense: \(expenseCount)")
    print("  • income: \(incomeCount)")

    print("\n📊 Розподіл по категоріях:")
    for (category, count) in categoryCount.sorted(by: { $0.value > $1.value }) {
        print("  • \(category): \(count)")
    }

    print("\n🚀 Тренування Text Classifier...")

    let startTime = Date()

    let classifier = try MLTextClassifier(
        trainingData: dataFrame,
        textColumn: "text",
        labelColumn: "label"
    )

    let time = Date().timeIntervalSince(startTime)
    print("✅ Завершено за \(String(format: "%.2f", time)) сек\n")

    // Метрики
    print("📈 Метрики тренування:")
    print("  Точність: \(String(format: "%.2f%%", (1.0 - classifier.trainingMetrics.classificationError) * 100))")

    print("\n📊 Метрики валідації:")
    print("  Точність: \(String(format: "%.2f%%", (1.0 - classifier.validationMetrics.classificationError) * 100))")

    // ТЕСТИ
    print("\n🧪 КОМПЛЕКСНІ ТЕСТИ:")
    print("─────────────────────────────────")

    let testCases = [
        // Їжа
        ("expense: Продукти в АТБ", "Їжа"),
        ("expense: Піца", "Їжа"),
        ("expense: Обід в ресторані", "Їжа"),
        ("expense: McDonald's", "Їжа"),

        // Покупки
        ("expense: Телефон", "Покупки"),
        ("expense: Одяг в Zara", "Покупки"),
        ("expense: Кросівки Nike", "Покупки"),

        // Здоров'я
        ("expense: Ліки в аптеці", "Здоров'я"),
        ("expense: Лікар", "Здоров'я"),
        ("expense: Стоматолог", "Здоров'я"),

        // Комунальні
        ("expense: Світло", "Комунальні"),
        ("expense: Інтернет Київстар", "Комунальні"),
        ("expense: Комунальні платежі", "Комунальні"),

        // Освіта
        ("expense: Курси англійської", "Освіта"),
        ("expense: Книги", "Освіта"),
        ("expense: Університет", "Освіта"),

        // Транспорт
        ("expense: Таксі Uber", "Транспорт"),
        ("expense: Бензин", "Транспорт"),
        ("expense: Метро", "Транспорт"),

        // Розваги
        ("expense: Кіно", "Розваги"),
        ("expense: PlayStation Plus", "Розваги"),
        ("expense: Steam", "Розваги"),

        // Income
        ("income: Зарплата", "Зарплата"),
        ("income: Фріланс проект", "Фріланс"),
        ("income: Дивіденди", "Інвестиції"),
        ("income: Подарунок", "Подарунок"),
        ("income: Бонус", "Бонус"),
    ]

    var correct = 0
    var categoryResults: [String: (correct: Int, total: Int)] = [:]

    for (testText, expected) in testCases {
        let prediction = try classifier.prediction(from: testText)
        let isCorrect = prediction == expected

        if isCorrect {
            correct += 1
        }

        // Оновлюємо статистику по категоріях
        if categoryResults[expected] == nil {
            categoryResults[expected] = (correct: 0, total: 0)
        }
        categoryResults[expected]?.total += 1
        if isCorrect {
            categoryResults[expected]?.correct += 1
        }

        let icon = isCorrect ? "✅" : "❌"
        let shortText = testText.replacingOccurrences(of: "expense: ", with: "").replacingOccurrences(of: "income: ", with: "")
        print("\(icon) '\(shortText)' → \(prediction) (очікується: \(expected))")
    }

    let accuracy = Double(correct) / Double(testCases.count) * 100
    print("\n📊 Загальна точність тестів: \(String(format: "%.1f%%", accuracy)) (\(correct)/\(testCases.count))")

    print("\n📊 Точність по категоріях:")
    for (category, stats) in categoryResults.sorted(by: { $0.key < $1.key }) {
        let catAccuracy = Double(stats.correct) / Double(stats.total) * 100
        print("  • \(category): \(String(format: "%.0f%%", catAccuracy)) (\(stats.correct)/\(stats.total))")
    }

    print("\n─────────────────────────────────\n")

    // Зберігаємо модель у поточній директорії (mlTraining)
    let modelPath = scriptDirectory.appendingPathComponent("TransactionCategoryClassifier.mlmodel")
    print("💾 Збереження моделі...")
    try classifier.write(to: modelPath)

    let attrs = try FileManager.default.attributesOfItem(atPath: modelPath.path)
    if let size = attrs[.size] as? Int64 {
        print("✅ Збережено: \(String(format: "%.1f", Double(size) / 1024)) KB")
        print("📍 Шлях: \(modelPath.path)")
    }
} catch {
    print("\n❌ Помилка: \(error)")
    exit(1)
}
