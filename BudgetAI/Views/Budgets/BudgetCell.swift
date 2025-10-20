//
//  BudgetCell.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class BudgetCell: UITableViewCell {

    static let reuseIdentifier = "BudgetCell"

    // MARK: - UI Components

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        return label
    }()

    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var budgetLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .default

        contentView.addSubview(iconLabel)
        contentView.addSubview(categoryNameLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(amountLabel)
        contentView.addSubview(budgetLabel)

        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(budgetLabel.snp.leading).offset(-12)
        }

        budgetLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
        }

        progressView.snp.makeConstraints { make in
            make.leading.equalTo(categoryNameLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(8)
            make.height.equalTo(8)
        }

        amountLabel.snp.makeConstraints { make in
            make.leading.equalTo(categoryNameLabel)
            make.top.equalTo(progressView.snp.bottom).offset(8)
        }
    }

    // MARK: - Configuration

    func configure(with displayModel: BudgetDisplayModel) {
        iconLabel.text = displayModel.categoryIcon
        categoryNameLabel.text = displayModel.categoryName

        progressView.progress = Float(displayModel.progressPercentage)
        progressView.progressTintColor = displayModel.progressColor

        amountLabel.text = "\(displayModel.spentAmount) з \(displayModel.budgetAmount)"

        budgetLabel.text = displayModel.remainingAmount
        budgetLabel.textColor = displayModel.progressColor
    }

    // Legacy method for backwards compatibility (if needed)
    func configure(with budget: Budget, spentAmount: Double) {
        iconLabel.text = budget.category?.icon ?? "📦"
        categoryNameLabel.text = budget.category?.name ?? "Без категорії"

        let budgetAmount = budget.amount
        let progress = Float(min(spentAmount / budgetAmount, 1.0))
        progressView.progress = progress

        // Determine if this is income or expense
        let isIncome = budget.category?.type == "income"

        if progress >= 1.0 {
            progressView.progressTintColor = isIncome ? .systemGreen : .systemRed
            budgetLabel.textColor = isIncome ? .systemGreen : .systemRed
        } else if progress >= 0.8 {
            progressView.progressTintColor = isIncome ? .systemGreen : .systemOrange
            budgetLabel.textColor = isIncome ? .systemGreen : .systemOrange
        } else {
            progressView.progressTintColor = isIncome ? .systemOrange : .systemGreen
            budgetLabel.textColor = isIncome ? .systemOrange : .systemGreen
        }

        // Use appropriate text for income vs expense
        let actionText = isIncome ? "Отримано" : "Витрачено"
        amountLabel.text = String(format: "%@: %.2f ₴ з %.2f ₴", actionText, spentAmount, budgetAmount)

        let remaining = budgetAmount - spentAmount
        budgetLabel.text = String(format: "%@%.2f ₴", remaining >= 0 ? "" : "+", abs(remaining))
    }
}
