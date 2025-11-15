//
//  StatisticsUIBuilder.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// Builder class responsible for creating and configuring UI components for the statistics screen
/// Provides static factory methods for creating labels, buttons, cards, and other UI elements
final class StatisticsUIBuilder {

    // MARK: - Labels

    /// Creates a configured UILabel with specified properties
    /// - Parameters:
    ///   - text: The text to display
    ///   - font: The font for the label
    ///   - color: The text color
    ///   - alignment: The text alignment (default: .left)
    ///   - numberOfLines: Number of lines (default: 1, 0 for unlimited)
    /// - Returns: Configured UILabel instance
    static func makeLabel(
        text: String,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        numberOfLines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        return label
    }

    // MARK: - Buttons

    /// Creates a period filter button with calendar icon
    /// - Returns: Configured UIButton for period selection
    static func makePeriodFilterButton() -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()

        configuration.title = L10n.Statistics.currentMonth
        configuration.baseForegroundColor = .label

        configuration.image = UIImage(
            systemName: "calendar",
            withConfiguration: UIImage.SymbolConfiguration(weight: .medium)
        )
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6.0

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }

        button.configuration = configuration
        button.showsMenuAsPrimaryAction = true
        return button
    }

    /// Creates a "Show More" button for displaying additional categories
    /// - Parameter target: The target object for button action
    /// - Parameter action: The selector to call when button is tapped
    /// - Returns: Configured UIButton for "Show More" action
    static func makeShowMoreButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Statistics.showMore, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.isHidden = true
        return button
    }

    // MARK: - Cards

    /// Creates income statistics card
    /// - Returns: Configured StatCardView for income display
    static func makeIncomeCard() -> StatCardView {
        return StatCardView(
            icon: "↑",
            title: L10n.Statistics.income,
            iconColor: .systemGreen,
            valueColor: .systemGreen
        )
    }

    /// Creates expense statistics card
    /// - Returns: Configured StatCardView for expense display
    static func makeExpenseCard() -> StatCardView {
        return StatCardView(
            icon: "↓",
            title: L10n.Statistics.expenses,
            iconColor: .systemRed,
            valueColor: .systemRed
        )
    }

    /// Creates balance statistics card
    /// - Returns: Configured StatCardView for balance display
    static func makeBalanceCard() -> StatCardView {
        return StatCardView(
            icon: "=",
            title: L10n.Statistics.balance,
            iconColor: .label,
            valueColor: .label
        )
    }

    // MARK: - Table Views

    /// Creates a table view for displaying category statistics
    /// - Parameters:
    ///   - delegate: The table view delegate
    ///   - dataSource: The table view data source
    /// - Returns: Configured UITableView for category stats
    static func makeCategoryStatsTableView(
        delegate: UITableViewDelegate,
        dataSource: UITableViewDataSource
    ) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(
            CategoryStatCell.self,
            forCellReuseIdentifier: CategoryStatCell.reuseIdentifier
        )
        tableView.delegate = delegate
        tableView.dataSource = dataSource
        return tableView
    }

    // MARK: - Empty State

    /// Creates an empty state label
    /// - Returns: Configured UILabel for empty state message
    static func makeEmptyStateLabel() -> UILabel {
        let label = makeLabel(
            text: "No data available to display statistics",
            font: .systemFont(ofSize: 16),
            color: .secondaryLabel,
            alignment: .center,
            numberOfLines: 0
        )
        label.isHidden = true
        return label
    }

    // MARK: - Layout Setup

    /// Configures scroll view and content view layout
    /// - Parameters:
    ///   - scrollView: The scroll view to configure
    ///   - contentView: The content view inside scroll view
    ///   - parentView: The parent view containing the scroll view
    static func setupScrollView(
        _ scrollView: UIScrollView,
        contentView: UIView,
        in parentView: UIView
    ) {
        parentView.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
    }

    /// Configures layout constraints for statistics cards
    /// - Parameters:
    ///   - incomeCard: The income statistics card
    ///   - expenseCard: The expense statistics card
    ///   - balanceCard: The balance statistics card
    ///   - in: The container view
    static func setupCardsLayout(
        incomeCard: UIView,
        expenseCard: UIView,
        balanceCard: UIView,
        in containerView: UIView
    ) {
        // Income Card
        incomeCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        // Expense Card
        expenseCard.snp.makeConstraints { make in
            make.top.equalTo(incomeCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        // Balance Card
        balanceCard.snp.makeConstraints { make in
            make.top.equalTo(expenseCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }
    }

    /// Configures layout constraints for category stats section
    /// - Parameters:
    ///   - titleLabel: The section title label
    ///   - tableView: The category stats table view
    ///   - showMoreButton: The show more button
    ///   - emptyStateLabel: The empty state label
    ///   - bottomSpacerView: The bottom spacer view
    ///   - topAnchor: The view to anchor below
    ///   - in: The container view
    static func setupCategoryStatsLayout(
        titleLabel: UILabel,
        tableView: UITableView,
        showMoreButton: UIButton,
        emptyStateLabel: UILabel,
        bottomSpacerView: UIView,
        topAnchor: UIView,
        in containerView: UIView
    ) {
        // Title Label
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(topAnchor.snp.bottom).offset(32)
            make.leading.equalTo(containerView.snp.leading).offset(16)
            make.trailing.equalTo(containerView.snp.trailing).offset(-16)
        }

        // Table View
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalTo(containerView.snp.leading)
            make.trailing.equalTo(containerView.snp.trailing)
            make.height.equalTo(0)
        }

        // Show More Button
        showMoreButton.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(8)
            make.centerX.equalTo(containerView.snp.centerX)
            make.height.equalTo(44)
        }

        // Empty State Label
        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.leading.equalTo(containerView.snp.leading).offset(40)
            make.trailing.equalTo(containerView.snp.trailing).offset(-40)
        }

        // Bottom Spacer
        bottomSpacerView.snp.makeConstraints { make in
            make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            make.leading.equalTo(containerView.snp.leading)
            make.trailing.equalTo(containerView.snp.trailing)
            make.height.equalTo(0)
            make.bottom.equalTo(containerView.snp.bottom)
        }
    }

    /// Updates the bottom spacer constraint based on show more button visibility
    /// - Parameters:
    ///   - bottomSpacerView: The bottom spacer view
    ///   - showMoreButton: The show more button
    ///   - tableView: The category stats table view
    static func updateBottomSpacerConstraint(
        bottomSpacerView: UIView,
        showMoreButton: UIButton,
        tableView: UIView
    ) {
        bottomSpacerView.snp.remakeConstraints { make in
            if showMoreButton.isHidden {
                make.top.equalTo(tableView.snp.bottom).offset(20)
            } else {
                make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            }
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }
}
