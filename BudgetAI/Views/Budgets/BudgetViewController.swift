//
//  BudgetViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class BudgetViewController: UIViewController {

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private var budgets: [Budget] = []
    private var currentMonth: Int16 = 0
    private var currentYear: Int16 = 0
    private var selectedMonth: Int16 = 0
    private var selectedYear: Int16 = 0

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemBackground
        tableView.register(BudgetCell.self, forCellReuseIdentifier: BudgetCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 32, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var previousMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(previousMonthTapped), for: .touchUpInside)
        return button
    }()

    private lazy var monthYearLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private lazy var nextMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
        return button
    }()

    private lazy var archiveLabel: UILabel = {
        let label = UILabel()
        label.text = "📦 Архів"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Немає бюджетів\nДодайте новий бюджет, натиснувши +"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCurrentMonthYear()
        setupNotifications()
        fetchBudgets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchBudgets()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Бюджети"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(previousMonthButton)
        view.addSubview(monthYearLabel)
        view.addSubview(nextMonthButton)
        view.addSubview(archiveLabel)
        view.addSubview(tableView)
        view.addSubview(addButton)
        view.addSubview(emptyStateLabel)

        previousMonthButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalTo(monthYearLabel)
            make.width.height.equalTo(32)
        }

        monthYearLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }

        nextMonthButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(monthYearLabel)
            make.width.height.equalTo(32)
        }

        archiveLabel.snp.makeConstraints { make in
            make.top.equalTo(monthYearLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(archiveLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.width.height.equalTo(56)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private func setupCurrentMonthYear() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        currentMonth = Int16(components.month ?? 1)
        currentYear = Int16(components.year ?? 2025)
        selectedMonth = currentMonth
        selectedYear = currentYear

        updateMonthYearLabel()
        updateNavigationButtons()
        updateUIForCurrentMonth()
    }

    private func updateMonthYearLabel() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let date = calendar.date(from: components) else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.dateFormat = "LLLL yyyy"
        monthYearLabel.text = dateFormatter.string(from: date).capitalized
    }

    private func updateNavigationButtons() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            previousMonthButton.isEnabled = false
            return
        }

        let prevComponents = calendar.dateComponents([.month, .year], from: previousMonthDate)
        let prevMonth = Int16(prevComponents.month ?? 1)
        let prevYear = Int16(prevComponents.year ?? 2025)

        let predicate = NSPredicate(format: "month == %d AND year == %d AND isActive == YES", prevMonth, prevYear)
        let previousBudgets: [Budget] = coreDataManager.fetch(Budget.self, predicate: predicate)

        previousMonthButton.isEnabled = !previousBudgets.isEmpty
        previousMonthButton.alpha = previousBudgets.isEmpty ? 0.3 : 1.0

        nextMonthButton.isEnabled = !(selectedMonth == currentMonth && selectedYear == currentYear)
        nextMonthButton.alpha = nextMonthButton.isEnabled ? 1.0 : 0.3
    }

    private func updateUIForCurrentMonth() {
        let isCurrentMonth = (selectedMonth == currentMonth && selectedYear == currentYear)

        addButton.isHidden = !isCurrentMonth
        archiveLabel.isHidden = isCurrentMonth

        if !isCurrentMonth {
            emptyStateLabel.text = "Немає бюджетів за цей місяць"
        } else {
            emptyStateLabel.text = "Немає бюджетів\nДодайте новий бюджет, натиснувши +"
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

    private func fetchBudgets() {
        let predicate = NSPredicate(format: "month == %d AND year == %d AND isActive == YES", selectedMonth, selectedYear)
        budgets = coreDataManager.fetch(Budget.self, predicate: predicate)
        tableView.reloadData()
        updateEmptyState()
        updateNavigationButtons()
        updateUIForCurrentMonth()
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !budgets.isEmpty
    }

    private func getSpentAmount(for category: Category) -> Double {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return 0
        }

        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startOfMonth as NSDate, endOfMonth as NSDate
        )

        let transactions: [Transaction] = coreDataManager.fetch(Transaction.self, predicate: predicate)
        return transactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        let addBudgetVC = AddBudgetViewController()
        addBudgetVC.delegate = self

        if let sheet = addBudgetVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(addBudgetVC, animated: true)
    }

    @objc private func handleTransactionChanged() {
        // Opening only if current month is on users view
        if selectedMonth == currentMonth && selectedYear == currentYear {
            fetchBudgets()
        }
    }

    @objc private func previousMonthTapped() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return
        }

        let prevComponents = calendar.dateComponents([.month, .year], from: previousMonthDate)
        selectedMonth = Int16(prevComponents.month ?? 1)
        selectedYear = Int16(prevComponents.year ?? 2025)

        updateMonthYearLabel()
        fetchBudgets()
    }

    @objc private func nextMonthTapped() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = Int(selectedYear)
        components.month = Int(selectedMonth)

        guard let currentDate = calendar.date(from: components),
              let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
            return
        }

        let nextComponents = calendar.dateComponents([.month, .year], from: nextMonthDate)
        let nextMonth = Int16(nextComponents.month ?? 1)
        let nextYear = Int16(nextComponents.year ?? 2025)

        // Constraint moving next after current month
        if nextYear > currentYear || (nextYear == currentYear && nextMonth > currentMonth) {
            return
        }

        selectedMonth = nextMonth
        selectedYear = nextYear

        updateMonthYearLabel()
        fetchBudgets()
    }
}

// MARK: - UITableViewDataSource

extension BudgetViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return budgets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BudgetCell.reuseIdentifier, for: indexPath) as? BudgetCell else {
            return UITableViewCell()
        }

        let budget = budgets[indexPath.row]
        if let category = budget.category {
            let spentAmount = getSpentAmount(for: category)
            cell.configure(with: budget, spentAmount: spentAmount)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BudgetViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Только для текущего месяца разрешаем удаление
        guard selectedMonth == currentMonth && selectedYear == currentYear else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, completion in
            guard let self = self else { return }
            let budget = self.budgets[indexPath.row]
            self.coreDataManager.delete(budget)
            self.fetchBudgets()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - AddBudgetDelegate

extension BudgetViewController: AddBudgetDelegate {

    func didAddBudget() {
        fetchBudgets()
    }
}
