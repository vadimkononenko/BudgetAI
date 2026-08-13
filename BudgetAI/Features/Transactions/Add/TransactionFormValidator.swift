//
//  TransactionFormValidator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import Foundation

/// A comprehensive validation result enum that can represent different types of validation outcomes
/// Used across all form validation to maintain consistency in error handling
enum FormValidationResult {
    case success
    case failure(String)

    /// Indicates whether the validation passed
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Returns the error message if validation failed, nil otherwise
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}

/// A validator specifically designed for transaction form data
/// Handles validation of amount, category selection, and provides character filtering for text input
struct TransactionFormValidator {

    // MARK: - Amount Validation

    /// Validates the transaction amount input
    /// Checks if the amount is non-empty, parseable, and within acceptable range
    /// - Parameter amountText: The text entered in the amount field
    /// - Returns: A ValidationResult containing either the parsed amount or an error message
    static func validateAmount(_ amountText: String?) -> ValidationResult {
        guard let text = amountText?.trimmingCharacters(in: .whitespaces), !text.isEmpty else {
            return .failure("Please enter an amount")
        }

        // Try to parse with CurrencyFormatter first
        if let amount = CurrencyFormatter.shared.parse(text) {
            return validateAmountValue(amount)
        }

        // Try direct Double conversion
        guard let amount = Double(text) else {
            return .failure("Please enter a valid amount")
        }

        return validateAmountValue(amount)
    }

    /// Validates the numeric value of the amount
    /// - Parameter amount: The parsed amount value
    /// - Returns: A ValidationResult indicating success or failure with appropriate message
    private static func validateAmountValue(_ amount: Double) -> ValidationResult {
        if amount <= 0 {
            return .failure("Amount must be greater than 0")
        }

        if amount > 1_000_000_000 {
            return .failure("Amount is too large")
        }

        return .success(amount)
    }

    // MARK: - Category Validation

    /// Validates that a category has been selected for the transaction
    /// - Parameter category: The selected category (can be nil)
    /// - Returns: A FormValidationResult indicating success or failure
    static func validateCategory(_ category: Category?) -> FormValidationResult {
        guard category != nil else {
            return .failure("Please select a category")
        }
        return .success
    }

    // MARK: - Description Validation

    /// Validates the transaction description
    /// Description is optional, so this mainly checks for length limits
    /// - Parameter description: The description text (can be nil or empty)
    /// - Returns: A FormValidationResult indicating success or failure
    static func validateDescription(_ description: String?) -> FormValidationResult {
        guard let text = description, !text.isEmpty else {
            // Description is optional, so empty is valid
            return .success
        }

        // Check if description is too long
        if text.count > 500 {
            return .failure("Description is too long (maximum 500 characters)")
        }

        return .success
    }

    // MARK: - Character Filtering

    /// Determines if a character is valid for amount input
    /// Only allows digits and decimal separators (. or ,)
    /// Also prevents multiple decimal separators
    /// - Parameters:
    ///   - character: The character to validate
    ///   - currentText: The current text in the field
    /// - Returns: true if the character should be allowed, false otherwise
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

    // MARK: - Complete Form Validation

    /// Validates all required fields of the transaction form
    /// This is the main validation method that should be called before saving
    /// - Parameters:
    ///   - amountText: The amount field text
    ///   - category: The selected category
    ///   - description: The description text (optional)
    /// - Returns: A tuple containing the validation result and the parsed amount if valid
    static func validateTransactionForm(
        amountText: String?,
        category: Category?,
        description: String?
    ) -> (result: FormValidationResult, amount: Double?) {
        // Validate amount first
        let amountValidation = validateAmount(amountText)
        guard amountValidation.isValid, let amount = amountValidation.value else {
            return (.failure(amountValidation.errorMessage ?? "Invalid amount"), nil)
        }

        // Validate category
        let categoryValidation = validateCategory(category)
        guard categoryValidation.isValid else {
            return (categoryValidation, nil)
        }

        // Validate description (optional field)
        let descriptionValidation = validateDescription(description)
        guard descriptionValidation.isValid else {
            return (descriptionValidation, nil)
        }

        // All validations passed
        return (.success, amount)
    }

    // MARK: - Date Validation

    /// Validates that the transaction date is not in the future
    /// - Parameter date: The date to validate
    /// - Returns: A FormValidationResult indicating success or failure
    static func validateDate(_ date: Date) -> FormValidationResult {
        if date > Date() {
            return .failure("Transaction date cannot be in the future")
        }
        return .success
    }

    // MARK: - Minimum Description Length for AI Prediction

    /// Checks if the description has enough characters for AI category prediction
    /// - Parameter description: The description text
    /// - Returns: true if the description is long enough for prediction, false otherwise
    static func isDescriptionLongEnoughForPrediction(_ description: String?) -> Bool {
        guard let text = description else { return false }
        return text.trimmingCharacters(in: .whitespaces).count >= 3
    }
}
