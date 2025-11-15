//
//  BudgetDetailViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 18.10.2025.
//

import UIKit
import SnapKit

/// Coordinator view controller for budget detail screen
/// Manages header, statistics, and transaction list child views
final class BudgetDetailViewController: UIViewController {

    // MARK: - Properties

    private let budget: Budget?
    private let category: Category?
    private let month: Int16
    private let year: Int16
    private let startDate: Date?
    private let endDate: Date?
    private let coreDataManager = CoreDataManager.shared

    private var transactions: [Transaction] = []
    private var maxTransaction: Transaction?
    private var minTransaction: Transaction?

    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        let currentMonth = Int16(components.month ?? 1)
        let currentYear = Int16(components.year ?? 2025)
        return month == currentMonth && year == currentYear
    }

    private var categoryType: String {
        return category?.type ?? "expense"
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

    private lazy var headerView: BudgetDetailHeaderView = {
        let view = BudgetDetailHeaderView()
        return view
    }()

    private lazy var statisticsView: BudgetStatisticsView = {
        let view = BudgetStatisticsView()
        return view
    }()

    private lazy var transactionListView: TransactionListView = {
        let view = TransactionListView()
        view.delegate = self
        return view
    }()

    // MARK: - Initialization

    /// Initialize with budget (from Budgets screen)
    ///
    /// - Parameters:
    ///   - budget: The budget to display details for
    ///   - month: Month number (1-12)
    ///   - year: Year number
    init(budget: Budget, month: Int16, year: Int16) {
        self.budget = budget
        self.category = budget.category
        self.month = month
        self.year = year
        self.startDate = nil
        self.endDate = nil
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize with category and custom date range (from Statistics screen)
    ///
    /// - Parameters:
    ///   - category: The category to display
    ///   - startDate: Period start date
    ///   - endDate: Period end date
    init(category: Category, startDate: Date, endDate: Date) {
        self.budget = nil
        self.category = category
        self.startDate = startDate
        self.endDate = endDate

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: startDate)
        self.month = Int16(components.month ?? 1)
        self.year = Int16(components.year ?? 2025)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureViews()
        fetchTransactions()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(statisticsView)
        contentView.addSubview(transactionListView)

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

        statisticsView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        transactionListView.snp.makeConstraints { make in
            make.top.equalTo(statisticsView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(contentView).offset(-16)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionChanged),
            name: .transactionDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionChanged),
            name: .transactionDidDelete,
            object: nil
        )
    }

    // MARK: - Configuration

    private func configureViews() {
        configureHeader()
        updateStatistics()
    }

    private func configureHeader() {
        let icon = category?.icon ?? "📦"
        let name = category?.name ?? "Category"
        let period = formatPeriod()

        headerView.configure(
            icon: icon,
            categoryName: name,
            period: period,
            isArchived: !isCurrentMonth,
            categoryType: categoryType
        )

        if categoryType == "income" {
            configureIncomeHeader()
        } else {
            configureExpenseHeader()
        }
    }

    private func configureExpenseHeader() {
        let spentAmount = getAmount(forType: "expense")
        let budgetAmount = budget?.amount ?? spentAmount
        let remaining = budgetAmount - spentAmount
        let progress = budgetAmount > 0 ? min(Float(spentAmount / budgetAmount), 1.0) : 0

        headerView.configureExpenseBudget(
            budgetAmount: budgetAmount,
            spentAmount: spentAmount,
            remaining: remaining,
            progress: progress
        )
    }

    private func configureIncomeHeader() {
        let achievedAmount = getAmount(forType: "income")
        let goalAmount = budget?.amount ?? achievedAmount
        let progress = goalAmount > 0 ? min(Float(achievedAmount / goalAmount), 1.0) : 0

        headerView.configureIncomeGoal(
            goalAmount: goalAmount,
            achievedAmount: achievedAmount,
            progress: progress
        )
    }

    private func updateStatistics() {
        let count = transactions.count
        let averageAmount = count > 0 ? transactions.reduce(0) { $0 + $1.amount } / Double(count) : 0
        maxTransaction = transactions.max(by: { $0.amount < $1.amount })
        minTransaction = transactions.min(by: { $0.amount < $1.amount })

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"
        let maxDate = maxTransaction != nil ? dateFormatter.string(from: maxTransaction!.date ?? Date()) : ""
        let minDate = minTransaction != nil ? dateFormatter.string(from: minTransaction!.date ?? Date()) : ""

        let data = BudgetStatisticsView.StatisticsData(
            count: count,
            averageAmount: averageAmount,
            maxAmount: maxTransaction?.amount ?? 0,
            maxDate: maxDate,
            minAmount: minTransaction?.amount ?? 0,
            minDate: minDate,
            categoryType: categoryType
        )

        statisticsView.configure(with: data)
    }

    // MARK: - Data Fetching

    private func fetchTransactions() {
        guard let category = category else { return }

        let predicate: NSPredicate

        if let start = startDate, let end = endDate {
            predicate = NSPredicate(
                format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
                category, categoryType, start as NSDate, end as NSDate
            )
        } else {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return
            }

            predicate = NSPredicate(
                format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
                category, categoryType, startOfMonth as NSDate, endOfMonth as NSDate
            )
        }

        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let result = coreDataManager.fetch(
            Transaction.self,
            predicate: predicate,
            sortDescriptors: [sortDescriptor]
        )

        switch result {
        case .success(let fetchedTransactions):
            transactions = fetchedTransactions
            transactionListView.configure(transactions: transactions, isCurrentMonth: isCurrentMonth)
            updateStatistics()
        case .failure(let error):
            print("Failed to fetch transactions: \(error)")
            transactions = []
        }
    }

    /// Gets total amount for specified transaction type
    ///
    /// - Parameter type: Transaction type ("expense" or "income")
    /// - Returns: Total amount
    private func getAmount(forType type: String) -> Double {
        guard let category = category else { return 0 }

        let predicate: NSPredicate

        if let start = startDate, let end = endDate {
            predicate = NSPredicate(
                format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
                category, type, start as NSDate, end as NSDate
            )
        } else {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return 0
            }

            predicate = NSPredicate(
                format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
                category, type, startOfMonth as NSDate, endOfMonth as NSDate
            )
        }

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate, sortDescriptors: [])

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }

    // MARK: - Helpers

    private func formatPeriod() -> String {
        if let start = startDate, let end = endDate {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "d MMMM yyyy"
            let startString = dateFormatter.string(from: start)
            let endString = dateFormatter.string(from: end)
            return "\(startString) - \(endString)"
        } else {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)
            if let date = calendar.date(from: components) {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "LLLL yyyy"
                return dateFormatter.string(from: date).capitalized
            }
        }
        return ""
    }

    // MARK: - Notifications

    @objc private func handleTransactionChanged() {
        if isCurrentMonth {
            fetchTransactions()
            configureViews()
        }
    }
}

// MARK: - TransactionListViewDelegate

extension BudgetDetailViewController: TransactionListViewDelegate {

    func transactionListView(_ view: TransactionListView, didSelectTransaction transaction: Transaction) {
        // Optional: Handle transaction selection if needed
    }

    func transactionListView(_ view: TransactionListView, didDeleteTransaction transaction: Transaction) {
        NotificationCenter.default.post(name: .transactionDidDelete, object: nil)
    }
}
