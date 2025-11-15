//
//  BudgetDetailHeaderView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

/// View displaying budget header information including category details and budget/income progress
final class BudgetDetailHeaderView: UIView {

    // MARK: - Properties

    var categoryType: String = "expense" {
        didSet { updateCardVisibility() }
    }

    // MARK: - UI Components - Header Info

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        label.textAlignment = .center
        return label
    }()

    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private lazy var periodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var archiveBadge: UILabel = {
        let label = UILabel()
        label.text = L10n.Budget.archive
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Expense Budget Card

    private lazy var budgetCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private lazy var budgetAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Бюджет"
        return label
    }()

    private lazy var budgetValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.textAlignment = .right
        return label
    }()

    private lazy var spentAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Витрачено"
        return label
    }()

    private lazy var spentValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var remainingAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var remainingValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var expenseProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var expenseProgressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Income Goal Card

    private lazy var incomeGoalCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private lazy var incomeGoalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.text = "Ціль доходу"
        return label
    }()

    private lazy var incomeGoalValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var achievedTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.text = "Досягнуто"
        return label
    }()

    private lazy var achievedValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .right
        return label
    }()

    private lazy var incomeProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemGreen
        return progressView
    }()

    private lazy var incomeProgressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(categoryNameLabel)
        containerView.addSubview(periodLabel)
        containerView.addSubview(archiveBadge)
        containerView.addSubview(budgetCardView)
        containerView.addSubview(incomeGoalCardView)

        // Expense card subviews
        budgetCardView.addSubview(budgetAmountLabel)
        budgetCardView.addSubview(budgetValueLabel)
        budgetCardView.addSubview(spentAmountLabel)
        budgetCardView.addSubview(spentValueLabel)
        budgetCardView.addSubview(remainingAmountLabel)
        budgetCardView.addSubview(remainingValueLabel)
        budgetCardView.addSubview(expenseProgressView)
        budgetCardView.addSubview(expenseProgressLabel)

        // Income card subviews
        incomeGoalCardView.addSubview(incomeGoalTitleLabel)
        incomeGoalCardView.addSubview(incomeGoalValueLabel)
        incomeGoalCardView.addSubview(achievedTitleLabel)
        incomeGoalCardView.addSubview(achievedValueLabel)
        incomeGoalCardView.addSubview(incomeProgressView)
        incomeGoalCardView.addSubview(incomeProgressLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        periodLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        archiveBadge.snp.makeConstraints { make in
            make.top.equalTo(periodLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        // Both cards occupy the same space
        [budgetCardView, incomeGoalCardView].forEach { card in
            card.snp.makeConstraints { make in
                make.top.equalTo(archiveBadge.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-20)
            }
        }

        // Expense card constraints
        budgetAmountLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        budgetValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(budgetAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        spentAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(budgetAmountLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        spentValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(spentAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        remainingAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(spentAmountLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        remainingValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(remainingAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        expenseProgressView.snp.makeConstraints { make in
            make.top.equalTo(remainingAmountLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        expenseProgressLabel.snp.makeConstraints { make in
            make.top.equalTo(expenseProgressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        // Income card constraints
        incomeGoalTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        incomeGoalValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(incomeGoalTitleLabel)
            make.trailing.equalToSuperview().inset(16)
        }
        achievedTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(incomeGoalTitleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
        }
        achievedValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(achievedTitleLabel)
            make.trailing.equalToSuperview().inset(16)
        }
        incomeProgressView.snp.makeConstraints { make in
            make.top.equalTo(achievedTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        incomeProgressLabel.snp.makeConstraints { make in
            make.top.equalTo(incomeProgressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Configuration

    /// Configures the main header information
    ///
    /// - Parameters:
    ///   - icon: Category icon emoji
    ///   - categoryName: Name of the category
    ///   - period: Period string to display
    ///   - isArchived: Whether to show archive badge
    ///   - categoryType: Type of category ("expense" or "income")
    func configure(
        icon: String,
        categoryName: String,
        period: String,
        isArchived: Bool,
        categoryType: String
    ) {
        iconLabel.text = icon
        categoryNameLabel.text = categoryName
        periodLabel.text = period
        archiveBadge.isHidden = !isArchived
        self.categoryType = categoryType
    }

    /// Configures the expense budget card with financial data
    ///
    /// - Parameters:
    ///   - budgetAmount: Total budget amount
    ///   - spentAmount: Amount spent so far
    ///   - remaining: Remaining budget (can be negative for overspending)
    ///   - progress: Progress percentage (0.0 to 1.0)
    func configureExpenseBudget(
        budgetAmount: Double,
        spentAmount: Double,
        remaining: Double,
        progress: Float
    ) {
        budgetValueLabel.text = String(format: "%.2f ₴", budgetAmount)
        spentValueLabel.text = String(format: "%.2f ₴", spentAmount)

        if remaining >= 0 {
            remainingAmountLabel.text = "Залишок"
            remainingValueLabel.text = String(format: "%.2f ₴", remaining)
            remainingValueLabel.textColor = .systemGreen
        } else {
            remainingAmountLabel.text = "Перевитрачено"
            remainingValueLabel.text = String(format: "%.2f ₴", abs(remaining))
            remainingValueLabel.textColor = .systemRed
        }

        expenseProgressView.progress = progress
        expenseProgressLabel.text = String(format: "%.0f%%", progress * 100)

        // Set colors based on progress
        if progress >= 1.0 {
            expenseProgressView.progressTintColor = .systemRed
            spentValueLabel.textColor = .systemRed
            expenseProgressLabel.textColor = .systemRed
        } else if progress >= 0.8 {
            expenseProgressView.progressTintColor = .systemOrange
            spentValueLabel.textColor = .systemOrange
            expenseProgressLabel.textColor = .systemOrange
        } else {
            expenseProgressView.progressTintColor = .systemGreen
            spentValueLabel.textColor = .systemGreen
            expenseProgressLabel.textColor = .systemGreen
        }
    }

    /// Configures the income goal card with financial data
    ///
    /// - Parameters:
    ///   - goalAmount: Target income goal
    ///   - achievedAmount: Amount achieved so far
    ///   - progress: Progress percentage (0.0 to 1.0)
    func configureIncomeGoal(
        goalAmount: Double,
        achievedAmount: Double,
        progress: Float
    ) {
        incomeGoalValueLabel.text = String(format: "%.2f ₴", goalAmount)
        achievedValueLabel.text = String(format: "%.2f ₴", achievedAmount)

        incomeProgressView.progress = progress
        incomeProgressLabel.text = String(format: "Achieved %.0f%% of goal", progress * 100)
    }

    // MARK: - Private Helpers

    private func updateCardVisibility() {
        budgetCardView.isHidden = (categoryType != "expense")
        incomeGoalCardView.isHidden = (categoryType != "income")
    }
}
