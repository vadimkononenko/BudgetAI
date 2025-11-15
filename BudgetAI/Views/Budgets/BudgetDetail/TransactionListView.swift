//
//  TransactionListView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

/// Delegate protocol for transaction list interactions
protocol TransactionListViewDelegate: AnyObject {
    /// Called when a transaction is selected
    func transactionListView(_ view: TransactionListView, didSelectTransaction: Transaction)

    /// Called when a transaction is deleted
    func transactionListView(_ view: TransactionListView, didDeleteTransaction: Transaction)
}

/// View displaying a grouped list of transactions with swipe-to-delete functionality
final class TransactionListView: UIView {

    // MARK: - Properties

    weak var delegate: TransactionListViewDelegate?
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    private var isCurrentMonth: Bool = false
    private var tableViewBottomConstraint: Constraint?
    private let coreDataManager = CoreDataManager.shared

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Транзакції"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.register(TransactionDetailCell.self, forCellReuseIdentifier: TransactionDetailCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No transactions for this period"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.isHidden = true
        return label
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
        addSubview(tableView)
        addSubview(emptyStateLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(-16)
            make.height.equalTo(0)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Configuration

    /// Configures the transaction list with data
    ///
    /// - Parameters:
    ///   - transactions: Array of transactions to display
    ///   - isCurrentMonth: Whether this is the current month (enables swipe to delete)
    func configure(transactions: [Transaction], isCurrentMonth: Bool) {
        self.isCurrentMonth = isCurrentMonth
        groupTransactionsByDate(transactions)
        updateTableView()
    }

    // MARK: - Private Helpers

    /// Groups transactions by date for sectioned display
    ///
    /// - Parameter transactions: Array of transactions to group
    private func groupTransactionsByDate(_ transactions: [Transaction]) {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction -> Date in
            calendar.startOfDay(for: transaction.date ?? Date())
        }

        groupedTransactions = grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    /// Updates table view display and height
    private func updateTableView() {
        let hasTransactions = !groupedTransactions.isEmpty
        emptyStateLabel.isHidden = hasTransactions
        tableView.reloadData()

        tableViewBottomConstraint?.deactivate()
        tableViewBottomConstraint = nil

        if hasTransactions {
            let totalHeight = calculateTableHeight()

            tableView.snp.updateConstraints { make in
                make.height.equalTo(totalHeight)
            }
            tableView.snp.makeConstraints { make in
                tableViewBottomConstraint = make.bottom.equalToSuperview().offset(-16).constraint
            }
        } else {
            tableView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    /// Calculates required height for table view based on content
    ///
    /// - Returns: Required height in points
    private func calculateTableHeight() -> CGFloat {
        let cellHeight: CGFloat = 70
        let sectionHeaderHeight: CGFloat = 35
        let sectionFooterSpacing: CGFloat = 10
        var totalHeight: CGFloat = 0

        for section in 0..<groupedTransactions.count {
            totalHeight += sectionHeaderHeight
            let numberOfRows = groupedTransactions[section].transactions.count
            totalHeight += cellHeight * CGFloat(numberOfRows)
            if section < groupedTransactions.count - 1 {
                totalHeight += sectionFooterSpacing
            }
        }

        let safetyPadding: CGFloat = 50
        totalHeight += safetyPadding

        return totalHeight
    }

    /// Returns the required height for the entire view including title and table
    ///
    /// - Returns: Total height needed
    func getRequiredHeight() -> CGFloat {
        if groupedTransactions.isEmpty {
            return 100 // Title + empty state
        }
        return 32 + calculateTableHeight() // Title height + table height
    }
}

// MARK: - UITableViewDataSource

extension TransactionListView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedTransactions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedTransactions[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TransactionDetailCell.reuseIdentifier,
            for: indexPath
        ) as? TransactionDetailCell else {
            return UITableViewCell()
        }

        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        cell.configure(with: transaction)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = groupedTransactions[section].date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "d MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

// MARK: - UITableViewDelegate

extension TransactionListView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        delegate?.transactionListView(self, didSelectTransaction: transaction)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            headerView.textLabel?.textColor = .secondaryLabel
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Only allow deletion in current month
        guard isCurrentMonth else {
            return nil
        }

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] _, _, completion in
            guard let self = self else { return }
            let transaction = self.groupedTransactions[indexPath.section].transactions[indexPath.row]

            let result = self.coreDataManager.delete(transaction)
            switch result {
            case .success:
                self.delegate?.transactionListView(self, didDeleteTransaction: transaction)
                completion(true)
            case .failure(let error):
                print("Failed to delete transaction: \(error)")
                completion(false)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
