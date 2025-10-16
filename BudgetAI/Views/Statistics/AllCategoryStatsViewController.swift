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

    init(categoryStats: [(category: Category, amount: Double)], totalExpense: Double) {
        self.categoryStats = categoryStats
        self.totalExpense = totalExpense
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
}
