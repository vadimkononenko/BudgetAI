//
//  TransactionDetailViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 19.10.2025.
//

import UIKit
import SnapKit

/// A view controller that displays and allows editing of transaction details.
///
/// This controller manages:
/// - Transaction header information (category, amount, date)
/// - Description editing
/// - Statistics display (budget impact, income goals, category stats)
/// - Transaction deletion
/// - Navigation to related budget/goal details
final class TransactionDetailViewController: UIViewController {

    // MARK: - Properties

    /// View model managing transaction data and business logic
    private let viewModel: TransactionDetailViewModel

    // MARK: - UI Components

    /// Main scroll view containing all content
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    /// Content view inside scroll view
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    /// Main vertical stack for organizing content cards
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Header Card Components

    /// Card containing transaction header information
    private lazy var headerCard = CardView()

    /// Label displaying category icon/emoji
    private lazy var categoryIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        return label
    }()

    /// Label displaying category name
    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Text field for editing transaction amount
    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .right
        textField.keyboardType = .decimalPad
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(amountDidChange), for: .editingChanged)
        return textField
    }()

    /// Label displaying currency symbol
    private lazy var currencyLabel: UILabel = {
        let label = UILabel()
        label.text = "₴"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Label displaying formatted transaction date
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Description Card Components

    /// Card containing transaction description
    private lazy var descriptionCard = CardView()

    /// Title label for description section
    private lazy var descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Transaction.description
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Text field for editing transaction description
    private lazy var descriptionTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.placeholder = L10n.Transaction.descriptionPlaceholder
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()

    // MARK: - Stats and Actions

    /// View displaying transaction statistics and impact
    private lazy var statsView = TransactionStatsView()

    /// Button for deleting the transaction
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Transaction.delete, for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    /// Initializes the view controller with a transaction
    /// - Parameter transaction: The transaction to display and edit
    init(transaction: Transaction) {
        self.viewModel = TransactionDetailViewModel(transaction: transaction)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupBindings()
        setupStatsViewCallbacks()
        viewModel.loadData()
    }

    // MARK: - Setup

    /// Configures the navigation bar appearance and title
    private func setupNavigationBar() {
        title = L10n.Transaction.transactionDetails
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    /// Sets up bindings between view model and view controller
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onChangesSaved = { [weak self] in
            self?.updateSaveButton()
        }

        viewModel.onTransactionDeleted = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            ErrorPresenter.show(error, in: self)
        }
    }

    /// Configures callbacks for the stats view
    private func setupStatsViewCallbacks() {
        statsView.onBudgetCardTapped = { [weak self] in
            self?.handleBudgetCardTapped()
        }

        statsView.onIncomeGoalCardTapped = { [weak self] in
            self?.handleIncomeGoalCardTapped()
        }
    }

    /// Sets up the view hierarchy and initial UI configuration
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)

        // Setup Header Card
        headerCard.addSubview(categoryIconLabel)
        headerCard.addSubview(categoryNameLabel)
        headerCard.addSubview(amountTextField)
        headerCard.addSubview(currencyLabel)
        headerCard.addSubview(dateLabel)

        // Setup Description Card
        descriptionCard.addSubview(descriptionTitleLabel)
        descriptionCard.addSubview(descriptionTextField)

        // Add cards to stack view
        contentStackView.addArrangedSubview(headerCard)
        contentStackView.addArrangedSubview(descriptionCard)
        contentStackView.addArrangedSubview(statsView)
        contentStackView.addArrangedSubview(deleteButton)

        setupConstraints()
    }

    /// Configures Auto Layout constraints for all UI components
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Header Card - internal constraints
        categoryIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(50)
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(categoryIconLabel)
            make.top.equalTo(categoryIconLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }

        currencyLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
        }

        amountTextField.snp.makeConstraints { make in
            make.trailing.equalTo(currencyLabel.snp.leading).offset(-4)
            make.top.equalToSuperview().offset(16)
            make.width.greaterThanOrEqualTo(80)
        }

        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(amountTextField.snp.bottom).offset(8)
        }

        // Description Card - internal constraints
        descriptionTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }

        descriptionTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(30)
        }

        // Delete Button
        deleteButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }

        // Add spacing before delete button
        contentStackView.setCustomSpacing(20, after: statsView)
    }

    // MARK: - UI Updates

    /// Updates all UI components with current view model data
    private func updateUI() {
        // Update header data
        categoryIconLabel.text = viewModel.categoryIcon
        categoryNameLabel.text = viewModel.categoryName

        amountTextField.textColor = viewModel.transactionTypeColor
        currencyLabel.textColor = viewModel.transactionTypeColor
        amountTextField.text = viewModel.amountText

        dateLabel.text = viewModel.formattedDate

        // Update description
        descriptionTextField.text = viewModel.description

        // Update statistics view
        updateStatsView()
    }

    /// Updates the statistics view with current data
    private func updateStatsView() {
        // Convert ViewModel types to View types
        let budgetCardData: BudgetCardData? = viewModel.budgetData.map { data in
            return BudgetCardData(
                progress: data.progress,
                progressTintColor: data.progressTintColor,
                remainingLabelColor: data.remainingLabelColor,
                remainingText: data.remainingText
            )
        }

        let incomeGoalCardData: IncomeGoalCardData? = viewModel.incomeGoalData.map { data in
            return IncomeGoalCardData(
                progress: data.progress,
                progressTintColor: .systemGreen,
                achievedLabelColor: .systemGreen,
                achievedText: String(format: "%.2f ₴ achieved", data.achieved)
            )
        }

        let categoryStatsCardData: CategoryStatsCardData?
        if let data = viewModel.categoryStatsData {
            categoryStatsCardData = CategoryStatsCardData(
                totalText: data.totalText,
                countText: data.countText
            )
        } else {
            categoryStatsCardData = nil
        }

        statsView.configureBudgetCard(with: budgetCardData)
        statsView.configureIncomeGoalCard(with: incomeGoalCardData)
        statsView.configureCategoryStatsCard(with: categoryStatsCardData)
    }

    /// Updates the save button visibility based on unsaved changes
    private func updateSaveButton() {
        if viewModel.hasUnsavedChanges {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: L10n.Transaction.save,
                style: .prominent,
                target: self,
                action: #selector(saveButtonTapped)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    // MARK: - Actions

    /// Handles changes to the description text field
    @objc private func textFieldDidChange() {
        viewModel.updateDescription(descriptionTextField.text)
        updateSaveButton()
    }

    /// Handles changes to the amount text field
    @objc private func amountDidChange() {
        guard let amountText = amountTextField.text else {
            return
        }

        // Try to validate the amount
        let validation = TransactionFormValidator.validateAmount(amountText)
        guard case .success(let currentAmount) = validation else {
            return
        }

        viewModel.updateAmount(currentAmount)
        updateSaveButton()
    }

    /// Handles save button tap - validates and persists changes
    @objc private func saveButtonTapped() {
        // Validate amount
        let amountValidation = TransactionFormValidator.validateAmount(amountTextField.text)
        guard case .success(let newAmount) = amountValidation else {
            if case .failure(let message) = amountValidation {
                showValidationError(message: message)
            }
            return
        }

        // Validate description
        let descriptionValidation = TransactionFormValidator.validateDescription(descriptionTextField.text)

        switch descriptionValidation {
        case .failure(let message):
            showValidationError(message: message)
            return
        case .success:
            break
        }

        // All validation passed, proceed with saving
        let result = viewModel.saveChanges(
            amount: newAmount,
            description: descriptionTextField.text
        )

        switch result {
        case .success:
            break // Handled by onChangesSaved callback
        case .failure(let error):
            showValidationError(message: error.localizedDescription)
        }
    }

    /// Handles delete button tap - shows confirmation and deletes transaction
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: L10n.Transaction.deleteTitle,
            message: L10n.Transaction.deleteMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.Transaction.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Budget.delete, style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTransaction()
        })

        present(alert, animated: true)
    }

    /// Handles budget card tap - navigates to budget detail screen
    private func handleBudgetCardTapped() {
        guard let budget = viewModel.getBudget() else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: viewModel.date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let detailVC = BudgetDetailViewController(budget: budget, month: month, year: year)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    /// Handles income goal card tap - navigates to goal detail screen
    private func handleIncomeGoalCardTapped() {
        guard let goal = viewModel.getBudget() else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: viewModel.date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let detailVC = BudgetDetailViewController(budget: goal, month: month, year: year)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Helper Methods

    /// Displays a validation error alert to the user
    /// - Parameter message: The error message to display
    private func showValidationError(message: String) {
        let alert = UIAlertController(
            title: L10n.Validation.error,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Validation.ok, style: .default))
        present(alert, animated: true)
    }
}
