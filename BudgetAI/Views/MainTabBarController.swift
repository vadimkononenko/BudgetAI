//
//  MainTabBarController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

final class MainTabBarController: UITabBarController {

    // MARK: - Initialization

    init(transactionsVC: TransactionsViewController, budgetVC: BudgetViewController, statisticsVC: StatisticsViewController) {
        super.init(nibName: nil, bundle: nil)
        setupTabBar()
        setupViewControllers(transactionsVC: transactionsVC, budgetVC: budgetVC, statisticsVC: statisticsVC)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup already done in init
    }

    // MARK: - Setup

    private func setupTabBar() {
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground
    }

    private func setupViewControllers(transactionsVC: TransactionsViewController, budgetVC: BudgetViewController, statisticsVC: StatisticsViewController) {
        let transactionsNav = UINavigationController(rootViewController: transactionsVC)
        transactionsNav.tabBarItem = UITabBarItem(
            title: "Транзакції",
            image: UIImage(systemName: "list.bullet"),
            selectedImage: UIImage(systemName: "list.bullet")
        )

        let budgetsNav = UINavigationController(rootViewController: budgetVC)
        budgetsNav.tabBarItem = UITabBarItem(
            title: "Бюджети",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        let statisticsNav = UINavigationController(rootViewController: statisticsVC)
        statisticsNav.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "chart.pie"),
            selectedImage: UIImage(systemName: "chart.pie.fill")
        )

        viewControllers = [transactionsNav, budgetsNav, statisticsNav]
    }
}
