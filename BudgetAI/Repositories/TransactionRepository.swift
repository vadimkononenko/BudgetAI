//
//  TransactionRepository.swift
//  BudgetAI
//
//  Created by Claude Code on 16.10.2025.
//

import Foundation

// MARK: - Transaction Repository Protocol

protocol TransactionRepository {
    func fetchAllTransactions() -> Result<[Transaction], CoreDataError>
    func fetchTransactions(type: String?, category: Category?) -> Result<[Transaction], CoreDataError>
    func fetchTransactions(from startDate: Date, to endDate: Date) -> Result<[Transaction], CoreDataError>
    func fetchTransactions(category: Category, from startDate: Date, to endDate: Date) -> Result<[Transaction], CoreDataError>
    func createTransaction(amount: Double, type: String, date: Date, description: String?, category: Category) -> Result<Transaction, CoreDataError>
    func deleteTransaction(_ transaction: Transaction) -> Result<Void, CoreDataError>
    func calculateTotalIncome(from startDate: Date?, to endDate: Date?) -> Result<Double, CoreDataError>
    func calculateTotalExpenses(from startDate: Date?, to endDate: Date?) -> Result<Double, CoreDataError>
    func calculateSpending(for category: Category, from startDate: Date, to endDate: Date) -> Result<Double, CoreDataError>
}
