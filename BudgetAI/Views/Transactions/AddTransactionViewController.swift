//
//  AddTransactionViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

/// View controller responsible for adding new transactions
/// This controller manages the transaction creation form, including:
/// - Amount input with validation
/// - Category selection with AI-powered prediction
/// - Transaction type selection (expense/income)
/// - Description and date selection
final class AddTransactionViewController: UIViewController {

    // MARK: - Properties

    /// Shared Core Data manager for persisting transactions
    private let coreDataManager = CoreDataManager.shared

    /// Service for AI-powered category prediction based on transaction description
    private let categorizationService = DIContainer.shared.categorizationService

    /// Currently selected category for the transaction
    private var selectedCategory: Category?

    /// Current transaction type: "expense" or "income"
    private var selectedType: String = "expense"

    /// All available categories filtered by current transaction type
    private var categories: [Category] = []

    /// Flag indicating if the category was automatically selected by AI
    /// Used to prevent overriding manual user selection
    private var isCategoryAutoSelected = false

    /// Background task for debounced category prediction
    /// Cancelled and recreated when user types in description field
    private var categorizationTask: Task<Void, Never>?

    // MARK: - UI Components

    /// Main scroll view containing all form elements
    private lazy var scrollView: UIScrollView = {
        TransactionFormBuilder.createScrollView()
    }()

    /// Content view inside scroll view to hold all form components
    private lazy var contentView: UIView = {
        TransactionFormBuilder.createContentView()
    }()

    /// Segmented control for selecting transaction type (expense/income)
    private lazy var typeSegmentedControl: UISegmentedControl = {
        TransactionFormBuilder.createTypeSegmentedControl(target: self, action: #selector(typeChanged))
    }()

    /// Text field for entering transaction amount
    private lazy var amountTextField: UITextField = {
        TransactionFormBuilder.createAmountTextField(delegate: self)
    }()

    /// Label displaying currency symbol next to amount
    private lazy var currencyLabel: UILabel = {
        TransactionFormBuilder.createCurrencyLabel()
    }()

    /// Button for category selection with dropdown menu
    private lazy var categoryButton: UIButton = {
        TransactionFormBuilder.createCategoryButton()
    }()

    /// Label displaying category icon inside category button
    private lazy var categoryIconLabel: UILabel = {
        TransactionFormBuilder.createCategoryIconLabel()
    }()

    /// Text view for entering transaction description
    private lazy var descriptionTextView: UITextView = {
        TransactionFormBuilder.createDescriptionTextView(delegate: self)
    }()

    /// Placeholder label for description text view
    private lazy var descriptionPlaceholder: UILabel = {
        TransactionFormBuilder.createDescriptionPlaceholder()
    }()

    /// Label for date picker
    private lazy var dateLabel: UILabel = {
        TransactionFormBuilder.createDateLabel()
    }()

    /// Date picker for selecting transaction date and time
    private lazy var datePicker: UIDatePicker = {
        TransactionFormBuilder.createDatePicker()
    }()

    /// Button to save the transaction
    private lazy var saveButton: UIButton = {
        TransactionFormBuilder.createSaveButton(target: self, action: #selector(saveButtonTapped))
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadCategories()
        updateCategoryMenu()
    }

    // MARK: - Setup

    /// Sets up the user interface by adding subviews and configuring constraints
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Add views to hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(typeSegmentedControl)
        contentView.addSubview(amountTextField)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(categoryButton)
        categoryButton.addSubview(categoryIconLabel)
        contentView.addSubview(descriptionTextView)
        descriptionTextView.addSubview(descriptionPlaceholder)
        contentView.addSubview(dateLabel)
        contentView.addSubview(datePicker)
        contentView.addSubview(saveButton)

        // Setup constraints using builder
        TransactionFormBuilder.setupConstraints(
            scrollView: scrollView,
            contentView: contentView,
            typeSegmentedControl: typeSegmentedControl,
            amountTextField: amountTextField,
            currencyLabel: currencyLabel,
            categoryButton: categoryButton,
            categoryIconLabel: categoryIconLabel,
            descriptionTextView: descriptionTextView,
            descriptionPlaceholder: descriptionPlaceholder,
            dateLabel: dateLabel,
            datePicker: datePicker,
            saveButton: saveButton
        )
    }

    /// Configures the navigation bar with title and cancel button
    private func setupNavigationBar() {
        title = L10n.Transaction.newTransaction
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    // MARK: - Data Management

    /// Loads categories from Core Data filtered by current transaction type
    private func loadCategories() {
        switch coreDataManager.fetch(Category.self) {
        case .success(let allCategories):
            categories = allCategories.filter { $0.type == selectedType }
        case .failure(let error):
            categories = []
            print("Failed to load categories: \(error.localizedDescription)")
        }
    }

    /// Updates the category button menu with available categories
    /// Creates menu actions for each category with icon and name
    private func updateCategoryMenu() {
        var menuActions: [UIAction] = []

        for category in categories {
            let title = "\(category.icon ?? "") \(category.name ?? "")"
            let action = UIAction(title: title) { [weak self] _ in
                self?.didSelectCategory(category)
            }
            menuActions.append(action)
        }

        categoryButton.menu = UIMenu(children: menuActions)
    }

    /// Handles manual category selection by the user
    /// Resets AI auto-selection flag to prevent AI from overriding user choice
    /// - Parameter category: The category selected by the user
    private func didSelectCategory(_ category: Category) {
        selectedCategory = category
        isCategoryAutoSelected = false // Reset flag on manual selection
        categoryButton.setTitle(category.name, for: .normal)
        categoryIconLabel.text = category.icon
    }

    // MARK: - Actions

    /// Handles transaction type change (expense/income)
    /// Reloads categories and triggers new category prediction if description exists
    @objc private func typeChanged() {
        selectedType = typeSegmentedControl.selectedSegmentIndex == 0 ? "expense" : "income"
        selectedCategory = nil
        isCategoryAutoSelected = false // Reset flag on type change
        categoryButton.setTitle(L10n.Transaction.selectCategory, for: .normal)
        categoryIconLabel.text = nil
        loadCategories()
        updateCategoryMenu()

        // Try to predict category again if description exists
        if !descriptionTextView.text.isEmpty {
            scheduleCategoryPrediction(delay: 0.3)
        }
    }

    /// Validates and saves the transaction
    /// Performs comprehensive validation before creating and persisting the transaction
    @objc private func saveButtonTapped() {
        // Validate form using validator
        let validation = TransactionFormValidator.validateTransactionForm(
            amountText: amountTextField.text,
            category: selectedCategory,
            description: descriptionTextView.text
        )

        // Check validation result
        guard validation.result.isValid, let amount = validation.amount else {
            if let errorMessage = validation.result.errorMessage {
                showAlert(title: "Error", message: errorMessage)
            }
            return
        }

        // Validate date
        let dateValidation = TransactionFormValidator.validateDate(datePicker.date)
        guard dateValidation.isValid else {
            if let errorMessage = dateValidation.errorMessage {
                showAlert(title: "Error", message: errorMessage)
            }
            return
        }

        // Create and save transaction
        let transaction = coreDataManager.create(Transaction.self)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.type = selectedType
        transaction.date = datePicker.date
        transaction.createdAt = Date()
        transaction.transactionDescription = descriptionTextView.text.isEmpty ? nil : descriptionTextView.text
        transaction.category = selectedCategory

        switch coreDataManager.saveContext() {
        case .success:
            NotificationCenter.default.post(name: .transactionDidAdd, object: nil)
            dismiss(animated: true)
        case .failure(let error):
            showAlert(title: "Error", message: "Failed to save transaction: \(error.localizedDescription)")
        }
    }

    /// Dismisses the view controller without saving
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - AI Category Prediction

    /// Schedules a category prediction task with debouncing
    /// Cancels any existing prediction task before creating a new one
    /// - Parameter delay: The delay in seconds before executing prediction
    private func scheduleCategoryPrediction(delay: TimeInterval) {
        categorizationTask?.cancel()

        categorizationTask = Task {
            do {
                try await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                predictCategory()
            } catch { }
        }
    }

    /// Predicts and auto-selects category based on transaction description
    /// Uses AI categorization service to suggest the most appropriate category
    /// Only applies auto-selection if user hasn't manually selected a category
    @MainActor
    private func predictCategory() {
        // Ensure description is not empty
        guard let description = descriptionTextView.text, !description.isEmpty else {
            return
        }

        // Ensure service is available
        guard let service = categorizationService else {
            return
        }

        // Get predicted category name
        guard let predictedCategoryName = service.predictCategory(for: description, type: selectedType) else {
            return
        }

        // Find matching category
        guard let category = categories.first(where: { $0.name == predictedCategoryName }) else {
            return
        }

        // Only auto-select if user hasn't manually chosen a category
        guard selectedCategory == nil || isCategoryAutoSelected else {
            return
        }

        // Apply AI prediction with animation
        selectedCategory = category
        isCategoryAutoSelected = true

        UIView.animate(withDuration: 0.3) {
            self.categoryButton.setTitle("\(L10n.Transaction.aiClassified) \(category.name ?? "")", for: .normal)
            self.categoryIconLabel.text = category.icon
        }

        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Helper Methods

    /// Displays an alert dialog with title and message
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AddTransactionViewController: UITextFieldDelegate {

    /// Validates character input for amount field
    /// Only allows numeric characters and decimal separators
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        return TransactionFormValidator.isValidAmountCharacter(string, currentText: currentText)
    }
}

// MARK: - UITextViewDelegate

extension AddTransactionViewController: UITextViewDelegate {

    /// Handles text changes in description field
    /// Manages placeholder visibility and triggers AI category prediction
    func textViewDidChange(_ textView: UITextView) {
        // Update placeholder visibility
        descriptionPlaceholder.isHidden = !textView.text.isEmpty

        // Exit early if text is empty
        guard !textView.text.isEmpty else {
            categorizationTask?.cancel()
            return
        }

        // Check if description is long enough for prediction
        guard TransactionFormValidator.isDescriptionLongEnoughForPrediction(textView.text) else {
            return
        }

        // Ensure service is available
        guard categorizationService != nil else {
            return
        }

        // Schedule prediction with debouncing
        scheduleCategoryPrediction(delay: 0.5)
    }
}
