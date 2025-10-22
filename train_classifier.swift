#!/usr/bin/env swift

import Foundation
import CreateML
import TabularData

print("🚀 Starting transaction classifier training...")

// Шлях до CSV файлу з тренувальними даними
let currentDirectory = FileManager.default.currentDirectoryPath
let dataURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("transaction_classifier_training.csv")

guard FileManager.default.fileExists(atPath: dataURL.path) else {
    print("❌ Error: Training data file not found at \(dataURL.path)")
    print("Please run 'swift generate_classifier_data.swift' first.")
    exit(1)
}

do {
    // Завантажуємо дані
    print("📊 Loading training data from: \(dataURL.path)")
    let data = try MLDataTable(contentsOf: dataURL)

    print("✅ Data loaded successfully!")
    print("   Rows: \(data.rows.count)")
    print("   Columns: \(data.columnNames)")

    // Розділяємо на тренувальну та тестову вибірки (80/20)
    let (trainingData, testingData) = data.randomSplit(by: 0.8, seed: 42)

    print("\n📈 Training set: \(trainingData.rows.count) rows")
    print("🧪 Testing set: \(testingData.rows.count) rows")

    // Створюємо та тренуємо Text Classifier модель
    print("\n🏋️ Training Text Classifier model...")
    print("   Target: label")
    print("   Feature: text")
    print("   Algorithm: Transfer Learning (Natural Language)")

    let classifier = try MLTextClassifier(
        trainingData: trainingData,
        textColumn: "text",
        labelColumn: "label"
    )

    print("\n✅ Model trained successfully!")

    // Оцінюємо модель на тестових даних
    print("\n📊 Evaluating model on test data...")
    let evaluationMetrics = classifier.evaluation(on: testingData, textColumn: "text", labelColumn: "label")

    print("\n📈 Model Performance Metrics:")
    print("   Validation Accuracy: \(String(format: "%.2f%%", evaluationMetrics.classificationError * 100))")

    // Тестуємо модель на прикладах
    print("\n🧪 Testing predictions:")
    let testExamples = [
        ("expense: АТБ супермаркет", "Їжа"),
        ("expense: Uber поїздка", "Транспорт"),
        ("expense: Netflix підписка", "Розваги"),
        ("expense: Аптека ліки", "Здоров'я"),
        ("expense: Zara одяг", "Покупки"),
        ("expense: Київенерго світло", "Комунальні"),
        ("expense: Coursera курс", "Освіта"),
        ("expense: Подарунок", "Інше")
    ]

    for (text, expectedCategory) in testExamples {
        let prediction = try classifier.prediction(from: text)
        let isCorrect = prediction == expectedCategory ? "✅" : "❌"
        print("   \(isCorrect) \"\(text)\" → \(prediction) (expected: \(expectedCategory))")
    }

    // Створюємо метадані для моделі
    let metadata = MLModelMetadata(
        author: "BudgetAI",
        shortDescription: "Класифікація транзакцій за категоріями на основі опису",
        version: "2.0"
    )

    // Зберігаємо модель
    let modelURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("TransactionCategoryClassifier.mlmodel")

    print("\n💾 Saving model to: \(modelURL.path)")
    try classifier.write(to: modelURL, metadata: metadata)

    print("\n✅ Model saved successfully!")
    print("\n🎉 Training complete!")
    print("\n📝 Next steps:")
    print("   1. Copy TransactionCategoryClassifier.mlmodel to BudgetAI/ML/ directory")
    print("   2. Replace the old model in Xcode project")
    print("   3. Rebuild the project")
    print("   4. Test the app with categories: Їжа, Транспорт, Розваги, Здоров'я, Покупки, Комунальні, Освіта, Інше")

} catch {
    print("❌ Error during training: \(error.localizedDescription)")
    print("   \(error)")
    exit(1)
}
