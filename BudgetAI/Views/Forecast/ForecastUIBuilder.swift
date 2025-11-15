//
//  ForecastUIBuilder.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// Responsible for building and configuring all UI components for the forecast view
/// Separates UI creation logic from view controller lifecycle management
final class ForecastUIBuilder {

    // MARK: - UI Components

    /// Main table view displaying forecast items
    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        table.backgroundView = UIView()
        return table
    }()

    /// Container view for the header section
    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    /// Label displaying the forecast month name
    let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()

    /// Subtitle label providing additional context
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        return label
    }()

    /// Card displaying the total forecasted amount
    lazy var totalCard: UIView = {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16

        // Title label (left)
        let titleLabel = UILabel()
        titleLabel.text = L10n.Forecast.expectedSpending
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        // Amount label (right)
        let amountLabel = UILabel()
        amountLabel.font = .systemFont(ofSize: 24, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right
        amountLabel.tag = 100 // Tag to access later for updates

        card.addSubview(titleLabel)
        card.addSubview(amountLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.baseline.equalTo(titleLabel.snp.baseline)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }

        card.snp.makeConstraints { make in
            make.height.equalTo(80)
        }

        return card
    }()

    /// View shown when no forecast data is available
    let emptyStateView: UIView = {
        let view = UIView()
        return view
    }()

    /// Label displaying empty state message
    let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    /// Icon label for empty state
    let emptyStateIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 64)
        label.text = "📊"
        label.textAlignment = .center
        return label
    }()

    /// Progress view showing data collection status
    let dataProgressView: DataProgressView = {
        let view = DataProgressView()
        return view
    }()

    /// Constraint reference for dynamic positioning of total card
    var totalCardTopConstraint: Constraint?

    // MARK: - Public Methods

    /// Updates the total amount displayed on the total card
    /// - Parameter amount: The formatted amount string to display
    func updateTotalAmount(_ amount: String) {
        if let amountLabel = totalCard.viewWithTag(100) as? UILabel {
            amountLabel.text = amount
        }
    }

    /// Builds the complete header view with all subviews and constraints
    /// - Returns: Configured header view ready to be set as table header
    func buildHeaderView() -> UIView {
        setupHeaderSubviews()
        setupHeaderConstraints()
        dataProgressView.isHidden = true
        updateTotalCardPosition()
        return headerView
    }

    /// Builds the empty state view with icon and message
    /// - Returns: Configured empty state view
    func buildEmptyStateView() -> UIView {
        setupEmptyStateSubviews()
        setupEmptyStateConstraints()
        return emptyStateView
    }

    /// Configures the table view with delegate, data source, and cell registration
    /// - Parameters:
    ///   - delegate: The table view delegate
    ///   - dataSource: The table view data source
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource) {
        tableView.delegate = delegate
        tableView.dataSource = dataSource
        tableView.register(ForecastCell.self, forCellReuseIdentifier: ForecastCell.reuseIdentifier)
        tableView.backgroundView = emptyStateView
    }

    /// Updates the position of the total card based on progress view visibility
    func updateTotalCardPosition() {
        totalCardTopConstraint?.deactivate()

        if dataProgressView.isHidden {
            totalCard.snp.makeConstraints { make in
                totalCardTopConstraint = make.top.equalTo(subtitleLabel.snp.bottom).offset(16).constraint
            }
        } else {
            totalCard.snp.makeConstraints { make in
                totalCardTopConstraint = make.top.equalTo(dataProgressView.snp.bottom).offset(16).constraint
            }
        }
    }

    /// Updates the height of the header view to fit its content
    /// - Parameter tableView: The table view containing the header
    func updateHeaderViewHeight(for tableView: UITableView) {
        guard let header = tableView.tableHeaderView else { return }

        header.frame.size.width = tableView.bounds.width

        let newSize = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )

        if header.frame.size.height != newSize.height {
            header.frame.size.height = newSize.height
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Private Methods

    /// Sets up the header view subviews hierarchy
    private func setupHeaderSubviews() {
        headerView.addSubview(monthLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(dataProgressView)
        headerView.addSubview(totalCard)
    }

    /// Configures Auto Layout constraints for header subviews
    private func setupHeaderConstraints() {
        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        dataProgressView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        totalCard.snp.makeConstraints { make in
            totalCardTopConstraint = make.top.equalTo(dataProgressView.snp.bottom).offset(16).constraint
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    /// Sets up the empty state view subviews hierarchy
    private func setupEmptyStateSubviews() {
        emptyStateView.addSubview(emptyStateIconLabel)
        emptyStateView.addSubview(emptyStateLabel)
    }

    /// Configures Auto Layout constraints for empty state subviews
    private func setupEmptyStateConstraints() {
        emptyStateIconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyStateIconLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
    }
}
