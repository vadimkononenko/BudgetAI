//
//  TransactionDetailViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 19.10.2025.
//

import UIKit
import SnapKit

final class TransactionDetailViewController: UIViewController {

    // MARK: - Properties

    private let transaction: Transaction
    private let coreDataManager = CoreDataManager.shared

    // Track changes
    private var hasUnsavedChanges = false
    private var originalAmount: Double = 0
    private var originalDescription: String?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    // Header Card
    private lazy var headerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var categoryIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        return label
    }()

    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .right
        textField.keyboardType = .decimalPad
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(amountDidChange), for: .editingChanged)
        return textField
    }()

    private lazy var currencyLabel: UILabel = {
        let label = UILabel()
        label.text = "₴"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    // Description Card
    private lazy var descriptionCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Опис"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var descriptionTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.placeholder = "Додати опис..."
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()

    // Budget Card
    private lazy var budgetCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(budgetCardTapped))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var budgetTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Бюджет"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var budgetProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var budgetRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private lazy var budgetChevronIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // Category Stats Card
    private lazy var categoryStatsCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var categoryStatsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "За місяць в категорії"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var totalAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var transactionsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    // Delete Button
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Видалити транзакцію", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    init(transaction: Transaction) {
        self.transaction = transaction
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
        loadData()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Деталі транзакції"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerCard)
        headerCard.addSubview(categoryIconLabel)
        headerCard.addSubview(categoryNameLabel)
        headerCard.addSubview(amountTextField)
        headerCard.addSubview(currencyLabel)
        headerCard.addSubview(dateLabel)

        contentView.addSubview(descriptionCard)
        descriptionCard.addSubview(descriptionTitleLabel)
        descriptionCard.addSubview(descriptionTextField)

        contentView.addSubview(budgetCard)
        budgetCard.addSubview(budgetTitleLabel)
        budgetCard.addSubview(budgetProgressView)
        budgetCard.addSubview(budgetRemainingLabel)
        budgetCard.addSubview(budgetChevronIcon)

        contentView.addSubview(categoryStatsCard)
        categoryStatsCard.addSubview(categoryStatsTitleLabel)
        categoryStatsCard.addSubview(totalAmountLabel)
        categoryStatsCard.addSubview(transactionsCountLabel)

        contentView.addSubview(deleteButton)

        setupConstraints()
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // Header Card
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

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

        // Description Card
        descriptionCard.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        descriptionTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }

        descriptionTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
            make.height.greaterThanOrEqualTo(30)
        }

        // Budget Card
        budgetCard.snp.makeConstraints { make in
            make.top.equalTo(descriptionCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        budgetTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }

        budgetProgressView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(budgetTitleLabel.snp.bottom).offset(8)
            make.height.equalTo(8)
        }

        budgetRemainingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(budgetProgressView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }

        budgetChevronIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(budgetRemainingLabel)
            make.width.height.equalTo(16)
        }

        // Category Stats Card
        categoryStatsCard.snp.makeConstraints { make in
            make.top.equalTo(budgetCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        categoryStatsTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }

        totalAmountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(categoryStatsTitleLabel.snp.bottom).offset(8)
        }

        transactionsCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(totalAmountLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-16)
        }

        // Delete Button
        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsCard.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    private func loadData() {
        // Save original values
        originalAmount = transaction.amount
        originalDescription = transaction.transactionDescription

        // Load header data
        categoryIconLabel.text = transaction.category?.icon ?? "📦"
        categoryNameLabel.text = transaction.category?.name ?? "Без категорії"

        let typeColor: UIColor = transaction.type == "expense" ? .systemRed : .systemGreen
        amountTextField.textColor = typeColor
        currencyLabel.textColor = typeColor
        amountTextField.text = String(format: "%.2f", transaction.amount)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy, HH:mm"
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateLabel.text = dateFormatter.string(from: transaction.date ?? Date())

        // Load description
        descriptionTextField.text = transaction.transactionDescription

        // Load budget data (if expense)
        if transaction.type == "expense", let category = transaction.category {
            loadBudgetData(for: category)
        }

        // Load category stats
        loadCategoryStats()
    }

    private func loadBudgetData(for category: Category) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: transaction.date ?? Date())
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let predicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d AND isActive == YES", category, month, year)
        let result = coreDataManager.fetch(Budget.self, predicate: predicate)

        switch result {
        case .success(let budgets):
            if let budget = budgets.first {
                budgetCard.isHidden = false

                // Get spent amount
                let spentAmount = getSpentAmount(for: category, month: month, year: year)
                let budgetAmount = budget.amount
                let remaining = budgetAmount - spentAmount
                let progress = Float(min(spentAmount / budgetAmount, 1.0))

                budgetProgressView.progress = progress

                if progress >= 1.0 {
                    budgetProgressView.progressTintColor = .systemRed
                    budgetRemainingLabel.textColor = .systemRed
                    budgetRemainingLabel.text = String(format: "Перевищено на %.2f ₴", abs(remaining))
                } else if progress >= 0.8 {
                    budgetProgressView.progressTintColor = .systemOrange
                    budgetRemainingLabel.textColor = .systemOrange
                    budgetRemainingLabel.text = String(format: "Залишилось %.2f ₴", remaining)
                } else {
                    budgetProgressView.progressTintColor = .systemGreen
                    budgetRemainingLabel.textColor = .systemGreen
                    budgetRemainingLabel.text = String(format: "Залишилось %.2f ₴", remaining)
                }
            }
        case .failure:
            budgetCard.isHidden = true
        }
    }

    private func getSpentAmount(for category: Category, month: Int16, year: Int16) -> Double {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }

    private func loadCategoryStats() {
        guard let category = transaction.category else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: transaction.date ?? Date())
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        var dateComponents = DateComponents()
        dateComponents.year = Int(year)
        dateComponents.month = Int(month)

        guard let startOfMonth = calendar.date(from: dateComponents),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, transaction.type ?? "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            let typeText = transaction.type == "expense" ? "витрачено" : "отримано"
            totalAmountLabel.text = String(format: "Всього %@: %.2f ₴", typeText, totalAmount)
            transactionsCountLabel.text = String(format: "Всього транзакцій: %d", transactions.count)
        case .failure:
            totalAmountLabel.text = "Немає даних"
            transactionsCountLabel.text = ""
        }
    }

    // MARK: - Actions

    @objc private func textFieldDidChange() {
        checkForChanges()
    }

    @objc private func amountDidChange() {
        checkForChanges()
    }

    private func checkForChanges() {
        let currentDescription = descriptionTextField.text
        let currentAmountText = amountTextField.text ?? ""
        let currentAmount = Double(currentAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0

        let descriptionChanged = currentDescription != originalDescription
        let amountChanged = abs(currentAmount - originalAmount) > 0.001

        hasUnsavedChanges = descriptionChanged || amountChanged
        updateSaveButton()
    }

    private func updateSaveButton() {
        if hasUnsavedChanges {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Зберегти",
                style: .prominent,
                target: self,
                action: #selector(saveButtonTapped)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func saveButtonTapped() {
        // Update amount
        if let amountText = amountTextField.text {
            let cleanedAmount = amountText.replacingOccurrences(of: ",", with: ".")
            if let newAmount = Double(cleanedAmount), newAmount > 0 {
                transaction.amount = newAmount
            } else {
                // Show error
                let alert = UIAlertController(
                    title: "Помилка",
                    message: "Введіть коректну суму",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        }

        // Update description
        transaction.transactionDescription = descriptionTextField.text

        // Save to Core Data
        let result = coreDataManager.saveContext()
        switch result {
        case .success:
            originalAmount = transaction.amount
            originalDescription = transaction.transactionDescription
            hasUnsavedChanges = false
            updateSaveButton()

            // Update UI
            if transaction.type == "expense", let category = transaction.category {
                loadBudgetData(for: category)
            }
            loadCategoryStats()

            NotificationCenter.default.post(name: .transactionDidAdd, object: nil)
        case .failure(let error):
            ErrorPresenter.show(error, in: self)
        }
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Видалити транзакцію?",
            message: "Цю дію неможливо скасувати",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            self?.deleteTransaction()
        })

        present(alert, animated: true)
    }

    private func deleteTransaction() {
        let result = coreDataManager.delete(transaction)
        switch result {
        case .success:
            NotificationCenter.default.post(name: .transactionDidDelete, object: nil)
            navigationController?.popViewController(animated: true)
        case .failure(let error):
            ErrorPresenter.show(error, in: self)
        }
    }

    @objc private func budgetCardTapped() {
        guard let category = transaction.category else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: transaction.date ?? Date())
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let predicate = NSPredicate(format: "category == %@ AND month == %d AND year == %d AND isActive == YES", category, month, year)
        let result = coreDataManager.fetch(Budget.self, predicate: predicate)

        switch result {
        case .success(let budgets):
            if let budget = budgets.first {
                let detailVC = BudgetDetailViewController(budget: budget, month: month, year: year)
                navigationController?.pushViewController(detailVC, animated: true)
            }
        case .failure:
            break
        }
    }

}
