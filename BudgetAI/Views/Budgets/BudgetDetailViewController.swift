//
//  BudgetDetailViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

final class BudgetDetailViewController: UIViewController {

    // MARK: - Properties

    private let budget: Budget
    private let month: Int16
    private let year: Int16
    private let coreDataManager = CoreDataManager.shared

    private var transactions: [Transaction] = []
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    private var tableViewBottomConstraint: Constraint?

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentMonth = Int16(components.month ?? 1)
        let currentYear = Int16(components.year ?? 2025)
        return month == currentMonth && year == currentYear
    }

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    // Header with budget info
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48)
        label.textAlignment = .center
        return label
    }()

    private lazy var categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private lazy var periodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var archiveBadge: UILabel = {
        let label = UILabel()
        label.text = "📦 Архів"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var budgetCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var budgetAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Бюджет"
        return label
    }()

    private lazy var budgetValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.textAlignment = .right
        return label
    }()

    private lazy var spentAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.text = "Витрачено"
        return label
    }()

    private lazy var spentValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var remainingAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var remainingValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    // Statistics Section
    private lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.text = "📊 Статистика"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private lazy var statsContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    // Transactions Section
    private lazy var transactionsLabel: UILabel = {
        let label = UILabel()
        label.text = "📝 Транзакції"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(TransactionDetailCell.self, forCellReuseIdentifier: TransactionDetailCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        return tableView
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Немає транзакцій за цей період"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    init(budget: Budget, month: Int16, year: Int16) {
        self.budget = budget
        self.month = month
        self.year = year
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureHeader()
        fetchTransactions()
        updateStatistics()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        headerView.addSubview(iconLabel)
        headerView.addSubview(categoryNameLabel)
        headerView.addSubview(periodLabel)
        headerView.addSubview(archiveBadge)
        headerView.addSubview(budgetCardView)

        budgetCardView.addSubview(budgetAmountLabel)
        budgetCardView.addSubview(budgetValueLabel)
        budgetCardView.addSubview(spentAmountLabel)
        budgetCardView.addSubview(spentValueLabel)
        budgetCardView.addSubview(remainingAmountLabel)
        budgetCardView.addSubview(remainingValueLabel)
        budgetCardView.addSubview(progressView)
        budgetCardView.addSubview(progressLabel)

        contentView.addSubview(statsLabel)
        contentView.addSubview(statsContainerView)
        statsContainerView.addSubview(statsStackView)

        contentView.addSubview(transactionsLabel)
        contentView.addSubview(tableView)
        contentView.addSubview(emptyStateLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(16)
        }

        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        categoryNameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        periodLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryNameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        archiveBadge.snp.makeConstraints { make in
            make.top.equalTo(periodLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        budgetCardView.snp.makeConstraints { make in
            make.top.equalTo(archiveBadge.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }

        budgetAmountLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }

        budgetValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(budgetAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        spentAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(budgetAmountLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        spentValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(spentAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        remainingAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(spentAmountLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        remainingValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(remainingAmountLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(remainingAmountLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }

        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        statsContainerView.snp.makeConstraints { make in
            make.top.equalTo(statsLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }

        statsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        transactionsLabel.snp.makeConstraints { make in
            make.top.equalTo(statsContainerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(transactionsLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(transactionsLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalTo(contentView).offset(-16)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionChanged),
            name: .transactionDidAdd,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionChanged),
            name: .transactionDidDelete,
            object: nil
        )
    }

    private func configureHeader() {
        iconLabel.text = budget.category?.icon ?? "📦"
        categoryNameLabel.text = budget.category?.name ?? "Категорія"

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        if let date = calendar.date(from: components) {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "uk_UA")
            dateFormatter.dateFormat = "LLLL yyyy"
            periodLabel.text = dateFormatter.string(from: date).capitalized
        }

        archiveBadge.isHidden = isCurrentMonth

        let spentAmount = getSpentAmount()
        let budgetAmount = budget.amount
        let remaining = budgetAmount - spentAmount
        let progress = min(Float(spentAmount / budgetAmount), 1.0)

        budgetValueLabel.text = String(format: "%.2f ₴", budgetAmount)
        spentValueLabel.text = String(format: "%.2f ₴", spentAmount)

        if remaining >= 0 {
            remainingAmountLabel.text = "Залишилось"
            remainingValueLabel.text = String(format: "%.2f ₴", remaining)
            remainingValueLabel.textColor = .systemGreen
        } else {
            remainingAmountLabel.text = "Перевитрата"
            remainingValueLabel.text = String(format: "%.2f ₴", abs(remaining))
            remainingValueLabel.textColor = .systemRed
        }

        progressView.progress = progress
        progressLabel.text = String(format: "%.0f%%", progress * 100)

        if progress >= 1.0 {
            progressView.progressTintColor = .systemRed
            spentValueLabel.textColor = .systemRed
            progressLabel.textColor = .systemRed
        } else if progress >= 0.8 {
            progressView.progressTintColor = .systemOrange
            spentValueLabel.textColor = .systemOrange
            progressLabel.textColor = .systemOrange
        } else {
            progressView.progressTintColor = .systemGreen
            spentValueLabel.textColor = .systemGreen
            progressLabel.textColor = .systemGreen
        }
    }

    private func getSpentAmount() -> Double {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
              let category = budget.category else {
            return 0
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }

    private func fetchTransactions() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
              let category = budget.category else {
            return
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let result = coreDataManager.fetch(Transaction.self, predicate: predicate, sortDescriptors: [sortDescriptor])

        switch result {
        case .success(let fetchedTransactions):
            transactions = fetchedTransactions
            groupTransactionsByDate()
        case .failure(let error):
            print("Failed to fetch transactions: \(error)")
            transactions = []
        }

        updateTableView()
    }

    private func groupTransactionsByDate() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction -> Date in
            calendar.startOfDay(for: transaction.date ?? Date())
        }

        groupedTransactions = grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func updateTableView() {
        let hasTransactions = !transactions.isEmpty
        emptyStateLabel.isHidden = hasTransactions
        tableView.reloadData()

        // Remove old bottom constraint if exists
        tableViewBottomConstraint?.deactivate()
        tableViewBottomConstraint = nil

        if hasTransactions {
            // Calculate height manually with all margins and paddings
            let cellHeight: CGFloat = 70 // Base cell height
            let sectionHeaderHeight: CGFloat = 35 // Section header with padding
            let sectionFooterSpacing: CGFloat = 10 // Space between sections

            var totalHeight: CGFloat = 0

            // Calculate total height by iterating through sections
            for section in 0..<groupedTransactions.count {
                // Add section header
                totalHeight += sectionHeaderHeight

                // Add cell heights
                let numberOfRows = groupedTransactions[section].transactions.count
                totalHeight += cellHeight * CGFloat(numberOfRows)

                // Add spacing after section (except last one)
                if section < groupedTransactions.count - 1 {
                    totalHeight += sectionFooterSpacing
                }
            }

            // Add extra padding for safety (accounts for any additional table view margins)
            let safetyPadding: CGFloat = 50
            totalHeight += safetyPadding

            print("📏 Calculated table height: \(totalHeight), sections: \(groupedTransactions.count), total transactions: \(transactions.count)")

            tableView.snp.updateConstraints { make in
                make.height.equalTo(totalHeight)
            }

            // Add bottom constraint to define contentView height
            tableView.snp.makeConstraints { make in
                tableViewBottomConstraint = make.bottom.equalTo(contentView).offset(-16).constraint
            }
        } else {
            // When empty, height is 0 and emptyStateLabel defines the bottom
            tableView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        // Update the view hierarchy
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateStatistics() {
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let count = transactions.count
        let averageAmount = count > 0 ? transactions.reduce(0) { $0 + $1.amount } / Double(count) : 0
        let maxAmount = transactions.map { $0.amount }.max() ?? 0
        let minAmount = transactions.map { $0.amount }.min() ?? 0

        let statCards = [
            ("Кількість", "\(count)"),
            ("Середній чек", String(format: "%.0f ₴", averageAmount)),
            ("Макс", String(format: "%.0f ₴", maxAmount)),
            ("Мін", String(format: "%.0f ₴", minAmount))
        ]

        for (title, value) in statCards {
            let card = createStatCard(title: title, value: value)
            statsStackView.addArrangedSubview(card)
        }
    }

    private func createStatCard(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

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

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-12)
        }

        return container
    }

    // MARK: - Actions

    @objc private func handleTransactionChanged() {
        if isCurrentMonth {
            fetchTransactions()
            configureHeader()
            updateStatistics()
        }
    }
}

// MARK: - UITableViewDataSource

extension BudgetDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedTransactions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedTransactions[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionDetailCell.reuseIdentifier, for: indexPath) as? TransactionDetailCell else {
            return UITableViewCell()
        }

        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        cell.configure(with: transaction)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = groupedTransactions[section].date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.dateFormat = "d MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

// MARK: - UITableViewDelegate

extension BudgetDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            headerView.textLabel?.textColor = .secondaryLabel
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isCurrentMonth else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, completion in
            guard let self = self else { return }
            let transaction = self.groupedTransactions[indexPath.section].transactions[indexPath.row]

            let result = self.coreDataManager.delete(transaction)
            switch result {
            case .success:
                NotificationCenter.default.post(name: .transactionDidDelete, object: nil)
                completion(true)
            case .failure(let error):
                ErrorPresenter.show(error, in: self)
                completion(false)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - TransactionDetailCell

final class TransactionDetailCell: UITableViewCell {

    static let reuseIdentifier = "TransactionDetailCell"

    // MARK: - UI Components

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
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

    func configure(with transaction: Transaction) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: transaction.date ?? Date())

        descriptionLabel.text = transaction.transactionDescription ?? "Без опису"

        let amount = transaction.amount
        amountLabel.text = String(format: "-%.2f ₴", amount)
        amountLabel.textColor = .systemRed

        photoIndicator.isHidden = transaction.photoData == nil
    }
}
