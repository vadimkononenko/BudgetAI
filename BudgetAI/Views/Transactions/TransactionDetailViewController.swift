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

    private let viewModel: TransactionDetailViewModel

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    // Main content stack
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()

    // Header Card
    private lazy var headerCard = CardView()

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
    private lazy var descriptionCard = CardView()

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
    private lazy var budgetCard: CardView = {
        let card = CardView()
        card.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(budgetCardTapped))
        card.addGestureRecognizer(tapGesture)
        return card
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

    // Income Goal Card
    private lazy var incomeGoalCard: CardView = {
        let card = CardView()
        card.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(incomeGoalCardTapped))
        card.addGestureRecognizer(tapGesture)
        return card
    }()

    private lazy var incomeGoalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ціль доходу"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var incomeGoalProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemGreen
        return progressView
    }()

    private lazy var incomeGoalAchievedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private lazy var incomeGoalChevronIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // Category Stats Card
    private lazy var categoryStatsCard = CardView()

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
        viewModel.loadData()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Деталі транзакції"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

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

        // Setup Budget Card
        budgetCard.addSubview(budgetTitleLabel)
        budgetCard.addSubview(budgetProgressView)
        budgetCard.addSubview(budgetRemainingLabel)
        budgetCard.addSubview(budgetChevronIcon)

        // Setup Income Goal Card
        incomeGoalCard.addSubview(incomeGoalTitleLabel)
        incomeGoalCard.addSubview(incomeGoalProgressView)
        incomeGoalCard.addSubview(incomeGoalAchievedLabel)
        incomeGoalCard.addSubview(incomeGoalChevronIcon)

        // Setup Category Stats Card
        categoryStatsCard.addSubview(categoryStatsTitleLabel)
        categoryStatsCard.addSubview(totalAmountLabel)
        categoryStatsCard.addSubview(transactionsCountLabel)

        // Add cards to stack view
        contentStackView.addArrangedSubview(headerCard)
        contentStackView.addArrangedSubview(descriptionCard)
        contentStackView.addArrangedSubview(budgetCard)
        contentStackView.addArrangedSubview(incomeGoalCard)
        contentStackView.addArrangedSubview(categoryStatsCard)
        contentStackView.addArrangedSubview(deleteButton)

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

        // Budget Card - internal constraints
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

        // Income Goal Card - internal constraints
        incomeGoalTitleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }

        incomeGoalProgressView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(incomeGoalTitleLabel.snp.bottom).offset(8)
            make.height.equalTo(8)
        }

        incomeGoalAchievedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(incomeGoalProgressView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }

        incomeGoalChevronIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(incomeGoalAchievedLabel)
            make.width.height.equalTo(16)
        }

        // Category Stats Card - internal constraints
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
            make.height.equalTo(50)
        }

        // Add spacing before delete button
        contentStackView.setCustomSpacing(20, after: categoryStatsCard)
    }

    private func updateUI() {
        // Load header data
        categoryIconLabel.text = viewModel.categoryIcon
        categoryNameLabel.text = viewModel.categoryName

        amountTextField.textColor = viewModel.transactionTypeColor
        currencyLabel.textColor = viewModel.transactionTypeColor
        amountTextField.text = viewModel.amountText

        dateLabel.text = viewModel.formattedDate

        // Load description
        descriptionTextField.text = viewModel.description

        // Update budget card
        updateBudgetCard()

        // Update income goal card
        updateIncomeGoalCard()

        // Update category stats
        updateCategoryStatsCard()
    }

    private func updateBudgetCard() {
        if let budgetData = viewModel.budgetData {
            budgetCard.isHidden = false
            budgetProgressView.progress = budgetData.progress
            budgetProgressView.progressTintColor = budgetData.progressTintColor
            budgetRemainingLabel.textColor = budgetData.remainingLabelColor
            budgetRemainingLabel.text = budgetData.remainingText
        } else {
            budgetCard.isHidden = true
        }
    }

    private func updateIncomeGoalCard() {
        if let incomeGoalData = viewModel.incomeGoalData {
            incomeGoalCard.isHidden = false
            incomeGoalProgressView.progress = incomeGoalData.progress
            incomeGoalProgressView.progressTintColor = incomeGoalData.progressTintColor
            incomeGoalAchievedLabel.textColor = incomeGoalData.achievedLabelColor
            incomeGoalAchievedLabel.text = incomeGoalData.achievedText
        } else {
            incomeGoalCard.isHidden = true
        }
    }

    private func updateCategoryStatsCard() {
        if let statsData = viewModel.categoryStatsData {
            totalAmountLabel.text = statsData.totalText
            transactionsCountLabel.text = statsData.countText
        } else {
            totalAmountLabel.text = "Немає даних"
            transactionsCountLabel.text = ""
        }
    }


    // MARK: - Actions

    @objc private func textFieldDidChange() {
        viewModel.updateDescription(descriptionTextField.text)
        updateSaveButton()
    }

    @objc private func amountDidChange() {
        let currentAmountText = amountTextField.text ?? ""
        let currentAmount = Double(currentAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        viewModel.updateAmount(currentAmount)
        updateSaveButton()
    }

    private func updateSaveButton() {
        if viewModel.hasUnsavedChanges {
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
        guard let amountText = amountTextField.text else { return }

        let cleanedAmount = amountText.replacingOccurrences(of: ",", with: ".")
        guard let newAmount = Double(cleanedAmount) else { return }

        let result = viewModel.saveChanges(amount: newAmount, description: descriptionTextField.text)

        switch result {
        case .success:
            break // Handled by onChangesSaved callback
        case .failure(let error):
            let alert = UIAlertController(
                title: "Помилка",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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
            self?.viewModel.deleteTransaction()
        })

        present(alert, animated: true)
    }

    @objc private func budgetCardTapped() {
        guard let budget = viewModel.getBudget() else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: viewModel.date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let detailVC = BudgetDetailViewController(budget: budget, month: month, year: year)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    @objc private func incomeGoalCardTapped() {
        guard let goal = viewModel.getBudget() else { return }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: viewModel.date)
        let month = Int16(components.month ?? 1)
        let year = Int16(components.year ?? 2025)

        let detailVC = BudgetDetailViewController(budget: goal, month: month, year: year)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

