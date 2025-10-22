//
//  MainTabBarController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

final class MainTabBarController: UITabBarController {

    // MARK: - Initialization

    init(transactionsVC: TransactionsViewController, budgetVC: BudgetViewController, statisticsVC: StatisticsViewController, forecastVC: ForecastViewController) {
        super.init(nibName: nil, bundle: nil)
        setupTabBar()
        setupViewControllers(transactionsVC: transactionsVC, budgetVC: budgetVC, statisticsVC: statisticsVC, forecastVC: forecastVC)
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

    private func setupViewControllers(transactionsVC: TransactionsViewController, budgetVC: BudgetViewController, statisticsVC: StatisticsViewController, forecastVC: ForecastViewController) {
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

        let forecastNav = UINavigationController(rootViewController: forecastVC)
        forecastNav.tabBarItem = UITabBarItem(
            title: "Прогноз",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis")
        )

        viewControllers = [transactionsNav, budgetsNav, statisticsNav, forecastNav]
    }
}
