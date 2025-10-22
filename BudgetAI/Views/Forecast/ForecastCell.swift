//
//  ForecastCell.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import UIKit

final class ForecastCell: UITableViewCell {

    static let reuseIdentifier = "ForecastCell"

    // MARK: - UI Components

    private let containerView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let categoryIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 32)
        return label
    }()

    private let categoryNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let predictedAmountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemRed
        label.textAlignment = .right
        return label
    }()

    private let historicalAverageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()

    private let confidenceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .right
        return label
    }()

    private let trendIconLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
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
        contentView.backgroundColor = .systemGroupedBackground
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(categoryIconLabel)
        containerView.addSubview(categoryNameLabel)
        containerView.addSubview(predictedAmountLabel)
        containerView.addSubview(historicalAverageLabel)
        containerView.addSubview(confidenceLabel)
        containerView.addSubview(trendIconLabel)

        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Category icon
            categoryIconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            categoryIconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            categoryIconLabel.widthAnchor.constraint(equalToConstant: 40),

            // Category name
            categoryNameLabel.centerYAnchor.constraint(equalTo: categoryIconLabel.centerYAnchor),
            categoryNameLabel.leadingAnchor.constraint(equalTo: categoryIconLabel.trailingAnchor, constant: 12),
            categoryNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: predictedAmountLabel.leadingAnchor, constant: -8),

            // Predicted amount
            predictedAmountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            predictedAmountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Historical average
            historicalAverageLabel.topAnchor.constraint(equalTo: categoryIconLabel.bottomAnchor, constant: 12),
            historicalAverageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            historicalAverageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

            // Trend icon
            trendIconLabel.centerYAnchor.constraint(equalTo: historicalAverageLabel.centerYAnchor),
            trendIconLabel.leadingAnchor.constraint(equalTo: historicalAverageLabel.trailingAnchor, constant: 8),

            // Confidence label
            confidenceLabel.centerYAnchor.constraint(equalTo: historicalAverageLabel.centerYAnchor),
            confidenceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    func configure(with forecast: CategoryForecast, categoryIcon: String, viewModel: ForecastViewModel) {
        categoryIconLabel.text = categoryIcon
        categoryNameLabel.text = forecast.categoryName
        predictedAmountLabel.text = viewModel.formattedAmount(forecast.predictedAmount)

        // Historical average
        let historicalText = "Середнє: \(viewModel.formattedAmount(forecast.historicalAverage))"
        historicalAverageLabel.text = historicalText

        // Confidence
        confidenceLabel.text = viewModel.confidenceText(for: forecast.confidence)
        if let color = UIColor(hex: viewModel.confidenceColor(for: forecast.confidence)) {
            confidenceLabel.textColor = color
        }

        // Trend
        let change = forecast.predictedAmount - forecast.historicalAverage
        if change > 0 {
            trendIconLabel.text = "↗"
            trendIconLabel.textColor = .systemRed
        } else if change < 0 {
            trendIconLabel.text = "↘"
            trendIconLabel.textColor = .systemGreen
        } else {
            trendIconLabel.text = "→"
            trendIconLabel.textColor = .systemGray
        }
    }
}
