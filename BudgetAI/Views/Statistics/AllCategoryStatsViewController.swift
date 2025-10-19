//
//  AllCategoryStatsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class AllCategoryStatsViewController: UIViewController {

    // MARK: - Properties

    private let categoryStats: [(category: Category, amount: Double)]
    private let totalExpense: Double
    private let selectedPeriod: StatisticsViewController.PeriodFilter
    private let coreDataManager = CoreDataManager.shared

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(CategoryStatCell.self, forCellReuseIdentifier: CategoryStatCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    // MARK: - Initialization

    init(categoryStats: [(category: Category, amount: Double)], totalExpense: Double, selectedPeriod: StatisticsViewController.PeriodFilter) {
        self.categoryStats = categoryStats
        self.totalExpense = totalExpense
        self.selectedPeriod = selectedPeriod
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Всі категорії витрат"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Helper Methods

    private func getDateRange() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .currentMonth:
            let components = calendar.dateComponents([.year, .month], from: Date())
            if let startOfMonth = calendar.date(from: components),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
                return (startOfMonth, endOfMonth)
            }

        case .specificMonth(let month, let year):
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)

            if let startOfMonth = calendar.date(from: components),
               let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
                return (startOfMonth, endOfMonth)
            }

        case .currentYear:
            let components = calendar.dateComponents([.year], from: Date())
            if let startOfYear = calendar.date(from: components) {
                let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear) ?? Date()
                return (startOfYear, endOfYear)
            }

        case .allTime:
            // Get the earliest and latest transaction dates
            let result = coreDataManager.fetch(Transaction.self)
            let allTransactions: [Transaction]

            switch result {
            case .success(let transactions):
                allTransactions = transactions
            case .failure:
                allTransactions = []
            }

            if let earliest = allTransactions.min(by: { $0.date ?? Date() < $1.date ?? Date() })?.date,
               let latest = allTransactions.max(by: { $0.date ?? Date() < $1.date ?? Date() })?.date {
                return (earliest, latest)
            }
        }

        // Fallback to current month
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let startOfMonth = calendar.date(from: components),
           let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) {
            return (startOfMonth, endOfMonth)
        }

        // Final fallback
        return (Date(), Date())
    }
}

// MARK: - UITableViewDataSource

extension AllCategoryStatsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryStats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryStatCell.reuseIdentifier, for: indexPath) as? CategoryStatCell else {
            return UITableViewCell()
        }

        let stat = categoryStats[indexPath.row]
        let percentage = totalExpense > 0 ? (stat.amount / totalExpense) * 100 : 0

        cell.configure(with: stat.category, amount: stat.amount, percentage: percentage)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AllCategoryStatsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let stat = categoryStats[indexPath.row]
        let dateRange = getDateRange()

        let detailVC = BudgetDetailViewController(
            category: stat.category,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
