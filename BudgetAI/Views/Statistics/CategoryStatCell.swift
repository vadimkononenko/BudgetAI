//
//  CategoryStatCell.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class CategoryStatCell: UITableViewCell {

    static let reuseIdentifier = "CategoryStatCell"

    // MARK: - UI Components

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        return label
    }()

    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .systemRed
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
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(iconLabel)
        contentView.addSubview(categoryNameLabel)
        contentView.addSubview(percentageLabel)
        contentView.addSubview(amountLabel)

        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
        }

        percentageLabel.snp.makeConstraints { make in
            make.leading.equalTo(categoryNameLabel)
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(4)
        }

        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with category: Category, amount: Double, percentage: Double) {
        iconLabel.text = category.icon
        categoryNameLabel.text = category.name
        percentageLabel.text = String(format: "%.1f%%", percentage)
        amountLabel.text = String(format: "%.2f ₴", amount)
    }
}
