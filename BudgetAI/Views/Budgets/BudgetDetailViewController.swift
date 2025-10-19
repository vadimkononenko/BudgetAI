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

    private let budget: Budget?
    private let category: Category?
    private let month: Int16
    private let year: Int16
    private let startDate: Date?
    private let endDate: Date?
    private let coreDataManager = CoreDataManager.shared

    private var transactions: [Transaction] = []
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] = []
    private var tableViewBottomConstraint: Constraint?
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

    // MARK: - Expense Budget Card

    private lazy var budgetCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true // Hidden by default
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

    private lazy var expenseProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        return progressView
    }()

    private lazy var expenseProgressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Income Goal Card
    
    private lazy var incomeGoalCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true // Hidden by default
        return view
    }()

    private lazy var incomeGoalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.text = "Ціль доходу"
        return label
    }()
    
    private lazy var incomeGoalValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var achievedTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.text = "Досягнуто"
        return label
    }()
    
    private lazy var achievedValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemGreen
        label.textAlignment = .right
        return label
    }()
    
    private lazy var incomeProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemGreen
        return progressView
    }()
    
    private lazy var incomeProgressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Common Sections
    
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
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private lazy var firstRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private lazy var secondRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

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

    /// Initialize with budget (from Budgets screen)
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
        configureView()
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
        
        // Add both cards to the header
        headerView.addSubview(budgetCardView)
        headerView.addSubview(incomeGoalCardView)

        // Setup Expense Card
        budgetCardView.addSubview(budgetAmountLabel)
        budgetCardView.addSubview(budgetValueLabel)
        budgetCardView.addSubview(spentAmountLabel)
        budgetCardView.addSubview(spentValueLabel)
        budgetCardView.addSubview(remainingAmountLabel)
        budgetCardView.addSubview(remainingValueLabel)
        budgetCardView.addSubview(expenseProgressView)
        budgetCardView.addSubview(expenseProgressLabel)
        
        // Setup Income Card
        incomeGoalCardView.addSubview(incomeGoalTitleLabel)
        incomeGoalCardView.addSubview(incomeGoalValueLabel)
        incomeGoalCardView.addSubview(achievedTitleLabel)
        incomeGoalCardView.addSubview(achievedValueLabel)
        incomeGoalCardView.addSubview(incomeProgressView)
        incomeGoalCardView.addSubview(incomeProgressLabel)

        contentView.addSubview(statsLabel)
        contentView.addSubview(statsContainerView)
        statsContainerView.addSubview(statsStackView)
        statsStackView.addArrangedSubview(firstRowStackView)
        statsStackView.addArrangedSubview(secondRowStackView)

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

        // Constraints for both cards (they will occupy the same space)
        [budgetCardView, incomeGoalCardView].forEach { card in
            card.snp.makeConstraints { make in
                make.top.equalTo(archiveBadge.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-20)
            }
        }
        
        // Expense Card Constraints
        budgetAmountLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
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
        expenseProgressView.snp.makeConstraints { make in
            make.top.equalTo(remainingAmountLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        expenseProgressLabel.snp.makeConstraints { make in
            make.top.equalTo(expenseProgressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Income Card Constraints
        incomeGoalTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        incomeGoalValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(incomeGoalTitleLabel)
            make.trailing.equalToSuperview().inset(16)
        }
        achievedTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(incomeGoalTitleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
        }
        achievedValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(achievedTitleLabel)
            make.trailing.equalToSuperview().inset(16)
        }
        incomeProgressView.snp.makeConstraints { make in
            make.top.equalTo(achievedTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        incomeProgressLabel.snp.makeConstraints { make in
            make.top.equalTo(incomeProgressView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }

        // Common Section Constraints
        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        statsContainerView.snp.makeConstraints { make in
            make.top.equalTo(statsLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(220)
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
    
    // MARK: - Configuration
    
    private func configureView() {
        configureMainHeaderInfo()
        
        if categoryType == "income" {
            configureIncomeHeader()
            incomeGoalCardView.isHidden = false
            budgetCardView.isHidden = true
        } else {
            configureExpenseHeader()
            incomeGoalCardView.isHidden = true
            budgetCardView.isHidden = false
        }
    }

    private func configureMainHeaderInfo() {
        iconLabel.text = category?.icon ?? "📦"
        categoryNameLabel.text = category?.name ?? "Категорія"

        if let start = startDate, let end = endDate {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "uk_UA")
            dateFormatter.dateFormat = "d MMMM yyyy"
            let startString = dateFormatter.string(from: start)
            let endString = dateFormatter.string(from: end)
            periodLabel.text = "\(startString) - \(endString)"
        } else {
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
        }
        archiveBadge.isHidden = isCurrentMonth
    }

    private func configureExpenseHeader() {
        let spentAmount = getAmount(forType: "expense")
        let budgetAmount = budget?.amount ?? spentAmount
        let remaining = budgetAmount - spentAmount
        let progress = budgetAmount > 0 ? min(Float(spentAmount / budgetAmount), 1.0) : 0

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

        expenseProgressView.progress = progress
        expenseProgressLabel.text = String(format: "%.0f%%", progress * 100)

        if progress >= 1.0 {
            expenseProgressView.progressTintColor = .systemRed
            spentValueLabel.textColor = .systemRed
            expenseProgressLabel.textColor = .systemRed
        } else if progress >= 0.8 {
            expenseProgressView.progressTintColor = .systemOrange
            spentValueLabel.textColor = .systemOrange
            expenseProgressLabel.textColor = .systemOrange
        } else {
            expenseProgressView.progressTintColor = .systemGreen
            spentValueLabel.textColor = .systemGreen
            expenseProgressLabel.textColor = .systemGreen
        }
    }
    
    private func configureIncomeHeader() {
        let achievedAmount = getAmount(forType: "income")
        let goalAmount = budget?.amount ?? achievedAmount
        let progress = goalAmount > 0 ? min(Float(achievedAmount / goalAmount), 1.0) : 0
        
        incomeGoalValueLabel.text = String(format: "%.2f ₴", goalAmount)
        achievedValueLabel.text = String(format: "%.2f ₴", achievedAmount)
        
        incomeProgressView.progress = progress
        incomeProgressLabel.text = String(format: "Досягнуто %.0f%% від цілі", progress * 100)
    }

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

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            return transactions.reduce(0) { $0 + $1.amount }
        case .failure:
            return 0
        }
    }

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

        tableViewBottomConstraint?.deactivate()
        tableViewBottomConstraint = nil

        if hasTransactions {
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

            tableView.snp.updateConstraints { make in
                make.height.equalTo(totalHeight)
            }
            tableView.snp.makeConstraints { make in
                tableViewBottomConstraint = make.bottom.equalTo(contentView).offset(-16).constraint
            }
        } else {
            tableView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateStatistics() {
        firstRowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        secondRowStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let count = transactions.count
        let averageAmount = count > 0 ? transactions.reduce(0) { $0 + $1.amount } / Double(count) : 0
        maxTransaction = transactions.max(by: { $0.amount < $1.amount })
        minTransaction = transactions.min(by: { $0.amount < $1.amount })
        let maxAmount = maxTransaction?.amount ?? 0
        let minAmount = minTransaction?.amount ?? 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"
        let maxDate = maxTransaction != nil ? dateFormatter.string(from: maxTransaction!.date ?? Date()) : ""
        let minDate = minTransaction != nil ? dateFormatter.string(from: minTransaction!.date ?? Date()) : ""
        
        let avgCardTitle = categoryType == "income" ? "Середній дохід" : "Середній чек"

        let countCard = createStatCard(title: "Кількість", value: "\(count)", subtitle: nil, tag: 0)
        firstRowStackView.addArrangedSubview(countCard)
        let avgCard = createStatCard(title: avgCardTitle, value: String(format: "%.0f ₴", averageAmount), subtitle: nil, tag: 1)
        firstRowStackView.addArrangedSubview(avgCard)
        let maxCard = createStatCard(title: "Макс", value: String(format: "%.0f ₴", maxAmount), subtitle: maxDate.isEmpty ? nil : maxDate, tag: 2)
        secondRowStackView.addArrangedSubview(maxCard)
        let minCard = createStatCard(title: "Мін", value: String(format: "%.0f ₴", minAmount), subtitle: minDate.isEmpty ? nil : minDate, tag: 3)
        secondRowStackView.addArrangedSubview(minCard)
    }

    private func createStatCard(title: String, value: String, subtitle: String?, tag: Int) -> UIView {
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

    // MARK: - Actions

    @objc private func handleTransactionChanged() {
        if isCurrentMonth {
            fetchTransactions()
            configureView()
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
