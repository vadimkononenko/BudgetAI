#!/usr/bin/env swift

import Foundation
import CreateML

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

    // Створюємо та тренуємо модель
    print("\n🏋️ Training Tabular Regressor model...")
    print("   Target: totalAmount")
    print("   Features: year, month, category, averageLastThreeMonths, season")

    let regressor = try MLRegressor(
        trainingData: trainingData,
        targetColumn: "totalAmount",
        featureColumns: ["year", "month", "category", "averageLastThreeMonths", "season"]
    )

    print("\n✅ Model trained successfully!")

    // Оцінюємо модель на тестових даних
    print("\n📊 Evaluating model on test data...")
    let evaluationMetrics = regressor.evaluation(on: testingData)

    print("\n📈 Model Performance Metrics:")
    print("   Root Mean Squared Error (RMSE): \(String(format: "%.2f", evaluationMetrics.rootMeanSquaredError))")
    print("   Maximum Error: \(String(format: "%.2f", evaluationMetrics.maximumError))")

    // Зберігаємо модель
    let modelURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("ExpenseForecastModel.mlmodel")

    print("\n💾 Saving model to: \(modelURL.path)")
    try regressor.write(to: modelURL)

    print("\n✅ Model saved successfully!")
    print("\n🎉 Training complete!")
    print("\n📝 Next steps:")
    print("   1. Copy ExpenseForecastModel.mlmodel to your Xcode project")
    print("   2. Add it to the project in Xcode (drag & drop into project navigator)")
    print("   3. Make sure 'Target Membership' is checked for your app target")
    print("   4. Xcode will automatically generate Swift class for the model")

} catch {
    print("❌ Error during training: \(error.localizedDescription)")
    exit(1)
}
