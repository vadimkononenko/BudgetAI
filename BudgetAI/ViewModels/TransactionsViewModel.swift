//
//  TransactionsViewModel.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation

final class TransactionsViewModel {

    // MARK: - Properties

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository

    enum FilterType {
        case all
        case expenses
        case income
    }

    struct FilterMenuItem {
        let title: String
        let category: Category?
        let isSelected: Bool
    }

    var transactions: [TransactionDisplayModel] = []
    var selectedFilter: FilterType = .all
    var selectedCategory: Category?
    var allCategories: [Category] = []

    var onTransactionsUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoading: ((Bool) -> Void)?

    // MARK: - Initialization

    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Public Methods

    func loadCategories() {
        let result = categoryRepository.fetchAllCategories()

        switch result {
        case .success(let categories):
            allCategories = categories
        case .failure(let error):
            onError?(error)
        }
    }

    func fetchTransactions() {
        onLoading?(true)

        let typeFilter: String? = {
            switch selectedFilter {
            case .all: return nil
            case .expenses: return "expense"
            case .income: return "income"
            }
        }()

        let result = transactionRepository.fetchTransactions(type: typeFilter, category: selectedCategory)

        onLoading?(false)

        switch result {
        case .success(let fetchedTransactions):
            transactions = fetchedTransactions.map { TransactionDisplayModel(transaction: $0) }
            onTransactionsUpdated?()

        case .failure(let error):
            onError?(error)
        }
    }

    func deleteTransaction(at index: Int) {
        guard index < transactions.count else { return }

        let transactionToDelete = transactions[index]

        // Fetch original transaction
        let result = transactionRepository.fetchAllTransactions()

        switch result {
        case .success(let fetchedTransactions):
            if let transaction = fetchedTransactions.first(where: { $0.id == transactionToDelete.id }) {
                let deleteResult = transactionRepository.deleteTransaction(transaction)

                switch deleteResult {
                case .success:
                    transactions.remove(at: index)
                    onTransactionsUpdated?()
                    // Post notification for budget screen to update
                    NotificationCenter.default.post(name: .transactionDidDelete, object: nil)

                case .failure(let error):
                    onError?(error)
                }
            }
        case .failure(let error):
            onError?(error)
        }
    }

    func setFilter(_ filter: FilterType) {
        selectedFilter = filter

        // Reset category filter if type doesn't match
        if let category = selectedCategory {
            let categoryType = category.type
            if (filter == .expenses && categoryType != "expense") ||
               (filter == .income && categoryType != "income") {
                selectedCategory = nil
            }
        }

        fetchTransactions()
    }

    func setCategory(_ category: Category?) {
        selectedCategory = category
        fetchTransactions()
    }

    func getFilteredCategories() -> [Category] {
        switch selectedFilter {
        case .all:
            return allCategories
        case .expenses:
            return allCategories.filter { $0.type == "expense" }
        case .income:
            return allCategories.filter { $0.type == "income" }
        }
    }

    func isEmpty() -> Bool {
        return transactions.isEmpty
    }

    func getTransaction(at index: Int) -> Transaction? {
        guard index < transactions.count else { return nil }

        let displayModel = transactions[index]
        let result = transactionRepository.fetchAllTransactions()

        switch result {
        case .success(let fetchedTransactions):
            return fetchedTransactions.first(where: { $0.id == displayModel.id })
        case .failure:
            return nil
        }
    }

    func getSegmentIndex() -> Int {
        switch selectedFilter {
        case .all: return 0
        case .expenses: return 1
        case .income: return 2
        }
    }

    func isCategorySelected(_ category: Category) -> Bool {
        return selectedCategory?.id == category.id
    }

    func hasSelectedCategory() -> Bool {
        return selectedCategory != nil
    }

    func getFilterMenuItems() -> [FilterMenuItem] {
        var items: [FilterMenuItem] = []

        // Add "All categories" option
        items.append(FilterMenuItem(
            title: "Всі категорії",
            category: nil,
            isSelected: selectedCategory == nil
        ))

        // Add filtered categories
        let filteredCategories = getFilteredCategories()
        for category in filteredCategories {
            let title = "\(category.icon ?? "") \(category.name ?? "")"
            items.append(FilterMenuItem(
                title: title,
                category: category,
                isSelected: isCategorySelected(category)
            ))
        }

        return items
    }
}
