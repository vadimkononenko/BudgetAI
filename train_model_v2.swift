#!/usr/bin/env swift

import Foundation
import CreateML
import TabularData

print("🚀 Starting expense forecast model training...")

// Шлях до CSV файлу з тренувальними даними
let currentDirectory = FileManager.default.currentDirectoryPath
let dataURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("expense_training_data.csv")

guard FileManager.default.fileExists(atPath: dataURL.path) else {
    print("❌ Error: Training data file not found at \(dataURL.path)")
    print("Please run 'swift generate_training_data.swift' first.")
    exit(1)
}

do {
    // Завантажуємо дані використовуючи DataFrame
    print("📊 Loading training data from: \(dataURL.path)")
    var data = try DataFrame(contentsOfCSVFile: dataURL)

    print("✅ Data loaded successfully!")
    print("   Rows: \(data.rows.count)")
    print("   Columns: \(data.columns.map { $0.name })")

    // Розділяємо на тренувальну та тестову вибірки (80/20)
    let (trainingSplit, testingSplit) = data.randomSplit(by: 0.8, seed: 42)
    let trainingData = DataFrame(trainingSplit)
    let testingData = DataFrame(testingSplit)

    print("\n📈 Training set: \(trainingData.rows.count) rows")
    print("🧪 Testing set: \(testingData.rows.count) rows")

    // Створюємо та тренуємо модель
    print("\n🏋️ Training Tabular Regressor model...")
    print("   Target: totalAmount")
    print("   Features: year, month, category, averageLastThreeMonths, season")

    let regressor = try MLLinearRegressor(
        trainingData: trainingData,
        targetColumn: "totalAmount"
    )

    print("\n✅ Model trained successfully!")

    // Оцінюємо модель на тестових даних
    print("\n📊 Evaluating model on test data...")
    let evaluationMetrics = regressor.evaluation(on: testingData)

    print("\n📈 Model Performance Metrics:")
    print("   Root Mean Squared Error (RMSE): \(String(format: "%.2f", evaluationMetrics.rootMeanSquaredError))")
    print("   Maximum Error: \(String(format: "%.2f", evaluationMetrics.maximumError))")

    // Створюємо метадані для моделі
    let metadata = MLModelMetadata(
        author: "BudgetAI",
        shortDescription: "Прогнозування витрат на наступний місяць на основі історії транзакцій",
        version: "1.0"
    )

    // Зберігаємо модель
    let modelURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("ExpenseForecastModel.mlmodel")

    print("\n💾 Saving model to: \(modelURL.path)")
    try regressor.write(to: modelURL, metadata: metadata)

    print("\n✅ Model saved successfully!")
    print("\n🎉 Training complete!")
    print("\n📝 Next steps:")
    print("   1. Copy ExpenseForecastModel.mlmodel to BudgetAI/Models/ directory")
    print("   2. Add it to the project in Xcode (drag & drop into project navigator)")
    print("   3. Make sure 'Target Membership' is checked for BudgetAI target")
    print("   4. Xcode will automatically generate Swift class: ExpenseForecastModel")

} catch {
    print("❌ Error during training: \(error.localizedDescription)")
    print("   \(error)")
    exit(1)
}
