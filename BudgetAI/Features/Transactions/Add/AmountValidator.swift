//
//  AmountValidator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

enum ValidationResult {
    case success(Double)
    case failure(String)

    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }

    var value: Double? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}

struct AmountValidator {

    static func validate(_ text: String?) -> ValidationResult {
        guard let text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else {
            return .failure("Будь ласка, введіть суму")
        }

        // Try to parse with CurrencyFormatter first
        if let amount = CurrencyFormatter.shared.parse(text) {
            return validateAmount(amount)
        }

        // Try direct Double conversion
        guard let amount = Double(text) else {
            return .failure("Введіть коректну суму")
        }

        return validateAmount(amount)
    }

    private static func validateAmount(_ amount: Double) -> ValidationResult {
        if amount <= 0 {
            return .failure("Сума має бути більше 0")
        }

        if amount > 1_000_000_000 {
            return .failure("Сума занадто велика")
        }

        return .success(amount)
    }

    static func isValidAmountCharacter(_ character: String, currentText: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let characterSet = CharacterSet(charactersIn: character)

        guard allowedCharacters.isSuperset(of: characterSet) else {
            return false
        }

        // Check for multiple decimal separators
        if (character == "." || character == ",") {
            if currentText.contains(".") || currentText.contains(",") {
                return false
            }
        }

        return true
    }
}
