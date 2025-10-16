//
//  TransactionCell.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class TransactionCell: UITableViewCell {

    static let reuseIdentifier = "TransactionCell"

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

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        return label
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
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
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(categoryNameLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(amountLabel)

        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(amountLabel.snp.leading).offset(-12)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(categoryNameLabel)
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(4)
            make.trailing.equalTo(amountLabel.snp.leading).offset(-12)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(categoryNameLabel)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
        }

        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
    }

    // MARK: - Configuration

    func configure(with transaction: Transaction) {
        iconLabel.text = transaction.category?.icon ?? "📦"
        categoryNameLabel.text = transaction.category?.name ?? "Без категорії"
        descriptionLabel.text = transaction.transactionDescription ?? "Опис відсутній"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        dateLabel.text = dateFormatter.string(from: transaction.date ?? Date())

        let amount = transaction.amount
        let isIncome = transaction.type == "income"
        amountLabel.text = String(format: "%@%.2f ₴", isIncome ? "+" : "-", amount)
        amountLabel.textColor = isIncome ? .systemGreen : .systemRed
    }
}
