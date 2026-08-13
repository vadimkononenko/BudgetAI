//
//  StatCardView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 20.10.2025.
//

import UIKit
import SnapKit

final class StatCardView: UIView {

    // MARK: - UI Components

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private var titleLabelLeadingConstraint: Constraint?

    // MARK: - Initialization

    init(icon: String, title: String, iconColor: UIColor, valueColor: UIColor) {
        super.init(frame: .zero)
        setupUI()
        configure(icon: icon, title: title, iconColor: iconColor, valueColor: valueColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12

        addSubview(iconLabel)
        addSubview(titleLabel)
        addSubview(valueLabel)

        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            titleLabelLeadingConstraint = make.leading.equalTo(iconLabel.snp.trailing).offset(12).constraint
            make.top.equalToSuperview().offset(16)
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration

    private func configure(icon: String, title: String, iconColor: UIColor, valueColor: UIColor) {
        iconLabel.text = icon
        iconLabel.textColor = iconColor
        titleLabel.text = title
        valueLabel.textColor = valueColor

        // Update constraints based on icon presence
        updateIconConstraints(hasIcon: !icon.isEmpty)
    }

    private func updateIconConstraints(hasIcon: Bool) {
        iconLabel.isHidden = !hasIcon

        titleLabelLeadingConstraint?.deactivate()

        if hasIcon {
            titleLabel.snp.makeConstraints { make in
                titleLabelLeadingConstraint = make.leading.equalTo(iconLabel.snp.trailing).offset(12).constraint
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                titleLabelLeadingConstraint = make.leading.equalToSuperview().offset(16).constraint
            }
        }
    }

    func updateValue(_ value: String, color: UIColor? = nil) {
        valueLabel.text = value
        if let color = color {
            valueLabel.textColor = color
        }
    }
}
