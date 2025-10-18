//
//  CoreDataTransactionRepository.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation
import CoreData

final class CoreDataTransactionRepository: TransactionRepository {

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    func fetchAllTransactions() -> Result<[Transaction], CoreDataError> {
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return coreDataManager.fetch(Transaction.self, predicate: nil, sortDescriptors: sortDescriptors)
    }

    func fetchTransactions(type: String?, category: Category?) -> Result<[Transaction], CoreDataError> {
        var predicates: [NSPredicate] = []

        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type))
        }

        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }

        let finalPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return coreDataManager.fetch(Transaction.self, predicate: finalPredicate, sortDescriptors: sortDescriptors)
    }

    func fetchTransactions(from startDate: Date, to endDate: Date) -> Result<[Transaction], CoreDataError> {
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return coreDataManager.fetch(Transaction.self, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    func fetchTransactions(category: Category, from startDate: Date, to endDate: Date) -> Result<[Transaction], CoreDataError> {
        let predicate = NSPredicate(format: "category == %@ AND date >= %@ AND date <= %@", category, startDate as NSDate, endDate as NSDate)
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        return coreDataManager.fetch(Transaction.self, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    func createTransaction(amount: Double, type: String, date: Date, description: String?, category: Category) -> Result<Transaction, CoreDataError> {
        let transaction = coreDataManager.create(Transaction.self)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.type = type
        transaction.date = date
        transaction.createdAt = Date()
        transaction.transactionDescription = description
        transaction.category = category

        return coreDataManager.saveContext().map { transaction }
    }

    func deleteTransaction(_ transaction: Transaction) -> Result<Void, CoreDataError> {
        return coreDataManager.delete(transaction)
    }

    func calculateTotalIncome(from startDate: Date?, to endDate: Date?) -> Result<Double, CoreDataError> {
        return calculateTotal(type: "income", from: startDate, to: endDate)
    }

    func calculateTotalExpenses(from startDate: Date?, to endDate: Date?) -> Result<Double, CoreDataError> {
        return calculateTotal(type: "expense", from: startDate, to: endDate)
    }

    func calculateSpending(for category: Category, from startDate: Date, to endDate: Date) -> Result<Double, CoreDataError> {
        let predicate = NSPredicate(
            format: "category == %@ AND type == %@ AND date >= %@ AND date <= %@",
            category, "expense", startDate as NSDate, endDate as NSDate
        )

        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            let total = transactions.reduce(0) { $0 + $1.amount }
            return .success(total)
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Helpers

    private func calculateTotal(type: String, from startDate: Date?, to endDate: Date?) -> Result<Double, CoreDataError> {
        var predicates: [NSPredicate] = [NSPredicate(format: "type == %@", type)]

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
        }

        if let endDate = endDate {
            predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let result = coreDataManager.fetch(Transaction.self, predicate: predicate)

        switch result {
        case .success(let transactions):
            let total = transactions.reduce(0) { $0 + $1.amount }
            return .success(total)
        case .failure(let error):
            return .failure(error)
        }
    }
}
