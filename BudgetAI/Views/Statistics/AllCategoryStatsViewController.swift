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

    private let categoryStats: [CategoryStatDisplayModel]
    private let totalExpense: Double
    private let selectedPeriod: StatisticsViewModel.PeriodFilter

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

    init(categoryStats: [CategoryStatDisplayModel], totalExpense: Double, selectedPeriod: StatisticsViewModel.PeriodFilter) {
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
            // For allTime, use a wide date range
            // TODO: Fetch actual transaction dates from repository
            let farPast = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            return (farPast, Date())
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
        cell.configure(with: stat)
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
