//
//  DIContainer.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

// MARK: - Dependency Injection Container

final class DIContainer {

    static let shared = DIContainer()

    // MARK: - Core Data

    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()

    // MARK: - Repositories

    private(set) lazy var budgetRepository: BudgetRepository = {
        return CoreDataBudgetRepository(coreDataManager: coreDataManager)
    }()

    private(set) lazy var transactionRepository: TransactionRepository = {
        return CoreDataTransactionRepository(coreDataManager: coreDataManager)
    }()

    private(set) lazy var categoryRepository: CategoryRepository = {
        return CoreDataCategoryRepository(coreDataManager: coreDataManager)
    }()

    // MARK: - ViewModels Factory

    func makeBudgetViewModel() -> BudgetViewModel {
        return BudgetViewModel(
            budgetRepository: budgetRepository,
            categoryRepository: categoryRepository
        )
    }

    func makeTransactionsViewModel() -> TransactionsViewModel {
        return TransactionsViewModel(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository
        )
    }

    func makeStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository
        )
    }

    // MARK: - View Controllers Factory

    func makeBudgetViewController() -> BudgetViewController {
        let viewModel = makeBudgetViewModel()
        return BudgetViewController(viewModel: viewModel)
    }

    func makeTransactionsViewController() -> TransactionsViewController {
        let viewModel = makeTransactionsViewModel()
        return TransactionsViewController(viewModel: viewModel)
    }

    func makeStatisticsViewController() -> StatisticsViewController {
        let viewModel = makeStatisticsViewModel()
        return StatisticsViewController(viewModel: viewModel)
    }

    func makeMainTabBarController() -> MainTabBarController {
        let budgetVC = makeBudgetViewController()
        let transactionsVC = makeTransactionsViewController()
        let statisticsVC = makeStatisticsViewController()

        return MainTabBarController(
            transactionsVC: transactionsVC,
            budgetVC: budgetVC,
            statisticsVC: statisticsVC
        )
    }

    // MARK: - Private Initialization

    private init() {}
}
