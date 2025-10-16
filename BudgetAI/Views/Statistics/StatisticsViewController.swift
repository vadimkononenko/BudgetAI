//
//  StatisticsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class StatisticsViewController: UIViewController {

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private var expenses: [Transaction] = []
    private var incomes: [Transaction] = []
    private var categoryStats: [(category: Category, amount: Double)] = []
    private var allCategoryStats: [(category: Category, amount: Double)] = []

    private var selectedPeriod: PeriodFilter = .currentMonth
    private var availableMonths: [(month: Int16, year: Int16)] = []

    enum PeriodFilter: Equatable {
        case currentMonth
        case specificMonth(month: Int16, year: Int16)
        case currentYear
        case allTime
    }

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var periodFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Поточний місяць", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .center
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private lazy var incomeCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var incomeIconLabel: UILabel = {
        let label = UILabel()
        label.text = "↑"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemGreen
        return label
    }()

    private lazy var incomeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Доходи"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var incomeValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .systemGreen
        return label
    }()

    private lazy var expenseCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var expenseIconLabel: UILabel = {
        let label = UILabel()
        label.text = "↓"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemRed
        return label
    }()

    private lazy var expenseTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Витрати"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var expenseValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .systemRed
        return label
    }()

    private lazy var balanceCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var balanceIconLabel: UILabel = {
        let label = UILabel()
        label.text = "="
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Баланс"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var balanceValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private lazy var categoryStatsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Топ-5 категорій витрат"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()

    private lazy var categoryStatsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(CategoryStatCell.self, forCellReuseIdentifier: CategoryStatCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var showMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Показати більше", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(showMoreButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Немає даних для відображення статистики"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var bottomSpacerView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAvailableMonths()
        updatePeriodFilterMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAvailableMonths()
        updatePeriodFilterMenu()
        fetchData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Статистика"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(periodFilterButton)
        contentView.addSubview(incomeCardView)
        contentView.addSubview(expenseCardView)
        contentView.addSubview(balanceCardView)

        incomeCardView.addSubview(incomeIconLabel)
        incomeCardView.addSubview(incomeTitleLabel)
        incomeCardView.addSubview(incomeValueLabel)

        expenseCardView.addSubview(expenseIconLabel)
        expenseCardView.addSubview(expenseTitleLabel)
        expenseCardView.addSubview(expenseValueLabel)

        balanceCardView.addSubview(balanceIconLabel)
        balanceCardView.addSubview(balanceTitleLabel)
        balanceCardView.addSubview(balanceValueLabel)

        contentView.addSubview(categoryStatsTitleLabel)
        contentView.addSubview(categoryStatsTableView)
        contentView.addSubview(showMoreButton)
        contentView.addSubview(emptyStateLabel)
        contentView.addSubview(bottomSpacerView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        periodFilterButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }

        incomeCardView.snp.makeConstraints { make in
            make.top.equalTo(periodFilterButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        incomeIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        incomeTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(incomeIconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
        }

        incomeValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        expenseCardView.snp.makeConstraints { make in
            make.top.equalTo(incomeCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        expenseIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        expenseTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(expenseIconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
        }

        expenseValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        balanceCardView.snp.makeConstraints { make in
            make.top.equalTo(expenseCardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        balanceIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        balanceTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(balanceIconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
        }

        balanceValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        categoryStatsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceCardView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        categoryStatsTableView.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        showMoreButton.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTableView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTitleLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        bottomSpacerView.snp.makeConstraints { make in
            make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }

    private func loadAvailableMonths() {
        let allTransactions: [Transaction] = coreDataManager.fetch(Transaction.self)
        let calendar = Calendar.current

        var monthYearSet: Set<String> = []
        var monthsArray: [(month: Int16, year: Int16)] = []

        for transaction in allTransactions {
            let components = calendar.dateComponents([.month, .year], from: transaction.date ?? Date())
            let month = Int16(components.month ?? 1)
            let year = Int16(components.year ?? 2025)
            let key = "\(year)-\(month)"

            if !monthYearSet.contains(key) {
                monthYearSet.insert(key)
                monthsArray.append((month: month, year: year))
            }
        }

        availableMonths = monthsArray.sorted { first, second in
            if first.year != second.year {
                return first.year > second.year
            }
            return first.month > second.month
        }
    }

    private func updatePeriodFilterMenu() {
        var menuChildren: [UIMenuElement] = []

        let currentMonthAction = UIAction(
            title: "Поточний місяць",
            image: selectedPeriod == .currentMonth ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.selectedPeriod = .currentMonth
            self?.periodFilterButton.setTitle("Поточний місяць", for: .normal)
            self?.updatePeriodFilterMenu()
            self?.fetchData()
        }
        menuChildren.append(currentMonthAction)

        if !availableMonths.isEmpty {
            var specificMonthActions: [UIAction] = []
            for monthYear in availableMonths {
                let calendar = Calendar.current
                var components = DateComponents()
                components.year = Int(monthYear.year)
                components.month = Int(monthYear.month)

                guard let date = calendar.date(from: components) else { continue }

                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "uk_UA")
                dateFormatter.dateFormat = "LLLL yyyy"
                let title = dateFormatter.string(from: date).capitalized

                var isSelected = false
                if case .specificMonth(let month, let year) = selectedPeriod {
                    isSelected = (month == monthYear.month && year == monthYear.year)
                }

                let action = UIAction(
                    title: title,
                    image: isSelected ? UIImage(systemName: "checkmark") : nil
                ) { [weak self] _ in
                    self?.selectedPeriod = .specificMonth(month: monthYear.month, year: monthYear.year)
                    self?.periodFilterButton.setTitle(title, for: .normal)
                    self?.updatePeriodFilterMenu()
                    self?.fetchData()
                }
                specificMonthActions.append(action)
            }

            let specificMonthMenu = UIMenu(title: "Вибрати місяць", children: specificMonthActions)
            menuChildren.append(specificMonthMenu)
        }

        let currentYearAction = UIAction(
            title: "Поточний рік",
            image: selectedPeriod == .currentYear ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.selectedPeriod = .currentYear
            self?.periodFilterButton.setTitle("Поточний рік", for: .normal)
            self?.updatePeriodFilterMenu()
            self?.fetchData()
        }
        menuChildren.append(currentYearAction)

        let allTimeAction = UIAction(
            title: "За весь час",
            image: selectedPeriod == .allTime ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.selectedPeriod = .allTime
            self?.periodFilterButton.setTitle("За весь час", for: .normal)
            self?.updatePeriodFilterMenu()
            self?.fetchData()
        }
        menuChildren.append(allTimeAction)

        periodFilterButton.menu = UIMenu(children: menuChildren)
    }

    private func fetchData() {
        let calendar = Calendar.current
        var predicate: NSPredicate?

        switch selectedPeriod {
        case .currentMonth:
            let components = calendar.dateComponents([.year, .month], from: Date())
            if let startOfMonth = calendar.date(from: components) {
                predicate = NSPredicate(format: "date >= %@", startOfMonth as NSDate)
            }

        case .specificMonth(let month, let year):
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            if let startOfMonth = calendar.date(from: components),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
                predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
            }

        case .currentYear:
            let components = calendar.dateComponents([.year], from: Date())
            if let startOfYear = calendar.date(from: components) {
                predicate = NSPredicate(format: "date >= %@", startOfYear as NSDate)
            }

        case .allTime:
            predicate = nil
        }

        let allTransactions: [Transaction] = coreDataManager.fetch(Transaction.self, predicate: predicate)

        expenses = allTransactions.filter { $0.type == "expense" }
        incomes = allTransactions.filter { $0.type == "income" }

        calculateCategoryStats()
        updateUI()
    }

    private func calculateCategoryStats() {
        var categoryAmounts: [String: (category: Category, amount: Double)] = [:]

        for expense in expenses {
            guard let category = expense.category else { continue }
            let categoryName = category.name ?? ""

            if let existing = categoryAmounts[categoryName] {
                categoryAmounts[categoryName] = (category, existing.amount + expense.amount)
            } else {
                categoryAmounts[categoryName] = (category, expense.amount)
            }
        }

        allCategoryStats = Array(categoryAmounts.values)
            .sorted { $0.amount > $1.amount }

        categoryStats = Array(allCategoryStats.prefix(5))

        let tableHeight = CGFloat(categoryStats.count * 60)
        categoryStatsTableView.snp.updateConstraints { make in
            make.height.equalTo(tableHeight)
        }
    }

    private func updateUI() {
        let totalIncome = incomes.reduce(0) { $0 + $1.amount }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let balance = totalIncome - totalExpense

        incomeValueLabel.text = String(format: "%.2f ₴", totalIncome)
        expenseValueLabel.text = String(format: "%.2f ₴", totalExpense)
        balanceValueLabel.text = String(format: "%.2f ₴", balance)
        balanceValueLabel.textColor = balance >= 0 ? .systemGreen : .systemRed

        categoryStatsTableView.reloadData()

        let hasData = !expenses.isEmpty || !incomes.isEmpty
        emptyStateLabel.isHidden = hasData
        categoryStatsTableView.isHidden = !hasData
        categoryStatsTitleLabel.isHidden = !hasData
        showMoreButton.isHidden = !(hasData && allCategoryStats.count > 5)

        // Update bottomSpacerView constraint based on showMoreButton visibility
        bottomSpacerView.snp.remakeConstraints { make in
            if showMoreButton.isHidden {
                make.top.equalTo(categoryStatsTableView.snp.bottom).offset(20)
            } else {
                make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            }
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func showMoreButtonTapped() {
        let allCategoryVC = AllCategoryStatsViewController(categoryStats: allCategoryStats, totalExpense: expenses.reduce(0) { $0 + $1.amount })
        navigationController?.pushViewController(allCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension StatisticsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryStats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryStatCell.reuseIdentifier, for: indexPath) as? CategoryStatCell else {
            return UITableViewCell()
        }

        let stat = categoryStats[indexPath.row]
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let percentage = totalExpense > 0 ? (stat.amount / totalExpense) * 100 : 0

        cell.configure(with: stat.category, amount: stat.amount, percentage: percentage)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StatisticsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
