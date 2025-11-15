//
//  TransactionStatsView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// A view component that displays transaction-related statistics including budget impact,
/// category statistics, and income goal progress.
///
/// This view manages three main cards:
/// - Budget Card: Shows budget consumption and remaining budget for the category
/// - Income Goal Card: Displays progress toward income goals
/// - Category Stats Card: Shows aggregated statistics for transactions in the same category
final class TransactionStatsView: UIView {

    // MARK: - Callbacks

    /// Callback invoked when the budget card is tapped
    var onBudgetCardTapped: (() -> Void)?

    /// Callback invoked when the income goal card is tapped
    var onIncomeGoalCardTapped: (() -> Void)?

    // MARK: - Budget Card Components

    /// Container card for budget information
    private lazy var budgetCard: CardView = {
        let card = CardView()
        card.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(budgetCardTapped))
        card.addGestureRecognizer(tapGesture)
        return card
    }()

    /// Title label for the budget section
    private lazy var budgetTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Transaction.budget
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Progress bar showing budget consumption
    private lazy var budgetProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    /// Label displaying remaining budget amount
    private lazy var budgetRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    /// Chevron icon indicating the budget card is tappable
    private lazy var budgetChevronIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Income Goal Card Components

    /// Container card for income goal information
    private lazy var incomeGoalCard: CardView = {
        let card = CardView()
        card.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(incomeGoalCardTapped))
        card.addGestureRecognizer(tapGesture)
        return card
    }()

    /// Title label for the income goal section
    private lazy var incomeGoalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Transaction.incomeGoal
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Progress bar showing income goal achievement
    private lazy var incomeGoalProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemGreen
        return progressView
    }()

    /// Label displaying achieved income amount
    private lazy var incomeGoalAchievedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    /// Chevron icon indicating the income goal card is tappable
    private lazy var incomeGoalChevronIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Category Stats Card Components

    /// Container card for category statistics
    private lazy var categoryStatsCard = CardView()

    /// Title label for the category statistics section
    private lazy var categoryStatsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Transaction.thisMonthInCategory
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Label displaying the total amount spent/earned in the category
    private lazy var totalAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    /// Label displaying the count of transactions in the category
    private lazy var transactionsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Sets up the view hierarchy and adds all subviews
    private func setupViews() {
        // Setup Budget Card
        addSubview(budgetCard)
        budgetCard.addSubview(budgetTitleLabel)
        budgetCard.addSubview(budgetProgressView)
        budgetCard.addSubview(budgetRemainingLabel)
        budgetCard.addSubview(budgetChevronIcon)

        // Setup Income Goal Card
        addSubview(incomeGoalCard)
        incomeGoalCard.addSubview(incomeGoalTitleLabel)
        incomeGoalCard.addSubview(incomeGoalProgressView)
        incomeGoalCard.addSubview(incomeGoalAchievedLabel)
        incomeGoalCard.addSubview(incomeGoalChevronIcon)

        // Setup Category Stats Card
        addSubview(categoryStatsCard)
        categoryStatsCard.addSubview(categoryStatsTitleLabel)
        categoryStatsCard.addSubview(totalAmountLabel)
        categoryStatsCard.addSubview(transactionsCountLabel)
    }

    /// Configures Auto Layout constraints for all components
    private func setupConstraints() {
        // Budget Card
        budgetCard.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
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

        // Income Goal Card
        incomeGoalCard.snp.makeConstraints { make in
            make.top.equalTo(budgetCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

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

        // Category Stats Card
        categoryStatsCard.snp.makeConstraints { make in
            make.top.equalTo(incomeGoalCard.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
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
    }

    // MARK: - Public Configuration Methods

    /// Updates the budget card with new data
    /// - Parameter data: Budget information to display, or nil to hide the card
    func configureBudgetCard(with data: BudgetCardData?) {
        if let budgetData = data {
            budgetCard.isHidden = false
            budgetProgressView.progress = budgetData.progress
            budgetProgressView.progressTintColor = budgetData.progressTintColor
            budgetRemainingLabel.textColor = budgetData.remainingLabelColor
            budgetRemainingLabel.text = budgetData.remainingText
        } else {
            budgetCard.isHidden = true
        }
    }

    /// Updates the income goal card with new data
    /// - Parameter data: Income goal information to display, or nil to hide the card
    func configureIncomeGoalCard(with data: IncomeGoalCardData?) {
        if let incomeGoalData = data {
            incomeGoalCard.isHidden = false
            incomeGoalProgressView.progress = incomeGoalData.progress
            incomeGoalProgressView.progressTintColor = incomeGoalData.progressTintColor
            incomeGoalAchievedLabel.textColor = incomeGoalData.achievedLabelColor
            incomeGoalAchievedLabel.text = incomeGoalData.achievedText
        } else {
            incomeGoalCard.isHidden = true
        }
    }

    /// Updates the category statistics card with new data
    /// - Parameter data: Category statistics to display, or nil to show "No data"
    func configureCategoryStatsCard(with data: CategoryStatsCardData?) {
        if let statsData = data {
            totalAmountLabel.text = statsData.totalText
            transactionsCountLabel.text = statsData.countText
        } else {
            totalAmountLabel.text = L10n.Transaction.noData
            transactionsCountLabel.text = ""
        }
    }

    // MARK: - Actions

    /// Handles tap gesture on the budget card
    @objc private func budgetCardTapped() {
        onBudgetCardTapped?()
    }

    /// Handles tap gesture on the income goal card
    @objc private func incomeGoalCardTapped() {
        onIncomeGoalCardTapped?()
    }
}

// MARK: - Data Models

/// Data structure for budget card configuration
struct BudgetCardData {
    /// Progress value between 0.0 and 1.0
    let progress: Float
    /// Color for the progress bar
    let progressTintColor: UIColor
    /// Color for the remaining amount label
    let remainingLabelColor: UIColor
    /// Text displaying remaining budget information
    let remainingText: String
}

/// Data structure for income goal card configuration
struct IncomeGoalCardData {
    /// Progress value between 0.0 and 1.0
    let progress: Float
    /// Color for the progress bar
    let progressTintColor: UIColor
    /// Color for the achieved amount label
    let achievedLabelColor: UIColor
    /// Text displaying achieved income information
    let achievedText: String
}

/// Data structure for category statistics card configuration
struct CategoryStatsCardData {
    /// Formatted text showing total amount in category
    let totalText: String
    /// Formatted text showing count of transactions
    let countText: String
}
