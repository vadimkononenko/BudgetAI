//
//  BudgetStatisticsView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

/// View displaying statistics cards for budget transactions (count, average, max, min)
final class BudgetStatisticsView: UIView {

    // MARK: - Data Model

    /// Statistics data structure
    struct StatisticsData {
        let count: Int
        let averageAmount: Double
        let maxAmount: Double
        let maxDate: String
        let minAmount: Double
        let minDate: String
        let categoryType: String
    }

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.BudgetDetail.statistics
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var firstRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var secondRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
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
        addSubview(titleLabel)
        addSubview(containerView)
        containerView.addSubview(statsStackView)
        statsStackView.addArrangedSubview(firstRowStackView)
        statsStackView.addArrangedSubview(secondRowStackView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(220)
        }

        statsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    /// Configures the statistics view with transaction data
    ///
    /// - Parameter data: Statistics data to display
    func configure(with data: StatisticsData) {
        // Clear existing cards
        firstRowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        secondRowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Determine average card title based on category type
        let avgCardTitle = data.categoryType == "income" ? "Average Income" : L10n.BudgetDetail.average

        // Create and add stat cards
        let countCard = createStatCard(
            title: L10n.BudgetDetail.count,
            value: "\(data.count)",
            subtitle: nil,
            tag: 0
        )
        firstRowStackView.addArrangedSubview(countCard)

        let avgCard = createStatCard(
            title: avgCardTitle,
            value: String(format: "%.0f ₴", data.averageAmount),
            subtitle: nil,
            tag: 1
        )
        firstRowStackView.addArrangedSubview(avgCard)

        let maxCard = createStatCard(
            title: L10n.BudgetDetail.maximum,
            value: String(format: "%.0f ₴", data.maxAmount),
            subtitle: data.maxDate.isEmpty ? nil : data.maxDate,
            tag: 2
        )
        secondRowStackView.addArrangedSubview(maxCard)

        let minCard = createStatCard(
            title: L10n.BudgetDetail.minimum,
            value: String(format: "%.0f ₴", data.minAmount),
            subtitle: data.minDate.isEmpty ? nil : data.minDate,
            tag: 3
        )
        secondRowStackView.addArrangedSubview(minCard)
    }

    // MARK: - Private Helpers

    /// Creates a stat card view with title, value, and optional subtitle
    ///
    /// - Parameters:
    ///   - title: Card title
    ///   - value: Main value to display
    ///   - subtitle: Optional subtitle (e.g., date)
    ///   - tag: View tag for identification
    /// - Returns: Configured stat card view
    private func createStatCard(
        title: String,
        value: String,
        subtitle: String?,
        tag: Int
    ) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.tag = tag

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 2
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        if let subtitle = subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
            subtitleLabel.textColor = .tertiaryLabel
            subtitleLabel.textAlignment = .center

            container.addSubview(subtitleLabel)

            valueLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(8)
            }

            subtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(valueLabel.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview().inset(8)
                make.bottom.equalToSuperview().offset(-12)
            }
        } else {
            valueLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(8)
                make.bottom.equalToSuperview().offset(-12)
            }
        }

        return container
    }
}
