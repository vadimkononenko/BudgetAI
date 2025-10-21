#!/usr/bin/env swift

import Foundation
import CoreML

print("🧪 Testing ExpenseForecastModel...")

// Завантажуємо модель
let modelURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("ExpenseForecastModel.mlmodel")

guard FileManager.default.fileExists(atPath: modelURL.path) else {
    print("❌ Model file not found at: \(modelURL.path)")
    exit(1)
}

print("✅ Model file found")

// Компілюємо модель
do {
    let compiledURL = try MLModel.compileModel(at: modelURL)
    print("✅ Model compiled successfully at: \(compiledURL.path)")

    let model = try MLModel(contentsOf: compiledURL)
    print("✅ Model loaded successfully")

    // Отримуємо опис моделі
    let description = model.modelDescription

    print("\n📊 Model Description:")
    print("   Inputs:")
    for input in description.inputDescriptionsByName {
        print("      - \(input.key): \(input.value.type)")
    }

    print("   Outputs:")
    for output in description.outputDescriptionsByName {
        print("      - \(output.key): \(output.value.type)")
    }

    print("\n✅ Model is ready to use in your iOS app!")
    print("\n📝 Next steps:")
    print("   1. Open BudgetAI.xcodeproj in Xcode")
    print("   2. Drag ExpenseForecastModel.mlmodel into the project navigator")
    print("   3. Make sure it's added to the BudgetAI target")
    print("   4. Build and run the project")

} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}
