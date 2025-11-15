//
//  TransactionDetailCell.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

/// Custom table view cell for displaying transaction details in budget detail view
final class TransactionDetailCell: UITableViewCell {

    static let reuseIdentifier = "TransactionDetailCell"

    // MARK: - UI Components

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var photoIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
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
        containerView.addSubview(timeLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(amountLabel)
        containerView.addSubview(photoIndicator)

        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        timeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(amountLabel.snp.leading).offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        amountLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.greaterThanOrEqualTo(80)
        }
        photoIndicator.snp.makeConstraints { make in
            make.trailing.equalTo(amountLabel.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    // MARK: - Configuration

    /// Configures the cell with transaction data
    ///
    /// - Parameter transaction: The transaction to display
    func configure(with transaction: Transaction) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: transaction.date ?? Date())
        descriptionLabel.text = transaction.transactionDescription ?? "Без опису"

        let amount = transaction.amount
        if transaction.type == "income" {
            amountLabel.text = String(format: "+%.2f ₴", amount)
            amountLabel.textColor = .systemGreen
        } else {
            amountLabel.text = String(format: "-%.2f ₴", amount)
            amountLabel.textColor = .systemRed
        }

        photoIndicator.isHidden = transaction.photoData == nil
    }
}
