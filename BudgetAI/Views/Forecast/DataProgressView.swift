//
//  DataProgressView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import UIKit
import SnapKit

final class DataProgressView: UIView {

    // MARK: - UI Components

    private let containerView: CardView = {
        let view = CardView()
        return view
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        label.text = "📊"
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let progressContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let progressBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 8
        return view
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let warningLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemOrange
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = L10n.Forecast.usingSimplified
        label.isHidden = true
        return label
    }()

    private var progressWidthConstraint: Constraint?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(progressContainerView)
        progressContainerView.addSubview(progressBarView)
        containerView.addSubview(progressLabel)
        containerView.addSubview(warningLabel)

        // Container
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Icon
        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
        }

        // Title
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        // Description
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        // Progress container
        progressContainerView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(16)
        }

        // Progress bar
        progressBarView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            progressWidthConstraint = make.width.equalTo(0).constraint
        }

        // Progress label
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(progressContainerView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        // Warning label
        warningLabel.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Configuration

    func configure(currentMonths: Int, requiredMonths: Int = 3, showWarning: Bool = false) {
        let progress = min(Double(currentMonths) / Double(requiredMonths), 1.0)

        // Update title
        if currentMonths == 0 {
            titleLabel.text = L10n.Forecast.startAddingTransactions
            descriptionLabel.text = String(format: L10n.Forecast.minMonthsRequired, requiredMonths)
            iconLabel.text = "📝"
        } else if currentMonths < requiredMonths {
            titleLabel.text = L10n.Forecast.collectingData
            let remaining = requiredMonths - currentMonths
            let monthWord = L10n.monthWord(for: remaining)
            descriptionLabel.text = String(format: L10n.Forecast.monthsRemaining, remaining, monthWord)
            iconLabel.text = "📊"
        } else {
            titleLabel.text = L10n.Forecast.enoughData
            descriptionLabel.text = L10n.Forecast.usingMLModel
            iconLabel.text = "✅"
        }

        // Update progress
        progressLabel.text = String(format: L10n.Forecast.monthsProgress, currentMonths, requiredMonths)

        // Animate progress bar
        layoutIfNeeded()
        let progressWidth = progressContainerView.bounds.width * CGFloat(progress)
        progressWidthConstraint?.update(offset: progressWidth)

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.layoutIfNeeded()
        }

        // Progress bar color
        if currentMonths >= requiredMonths {
            progressBarView.backgroundColor = .systemGreen
        } else if currentMonths >= 1 {
            progressBarView.backgroundColor = .systemOrange
        } else {
            progressBarView.backgroundColor = .systemGray
        }

        // Warning
        warningLabel.isHidden = !showWarning
    }
}
