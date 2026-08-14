//
//  TransactionRepository.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

protocol TransactionRepository {
    func fetchAllTransactions() -> Result<[Transaction], RepositoryError>
    func fetchTransactions(type: String?, category: Category?) -> Result<[Transaction], RepositoryError>
    func fetchTransactions(from startDate: Date, to endDate: Date) -> Result<[Transaction], RepositoryError>
    func fetchTransactions(category: Category, from startDate: Date, to endDate: Date) -> Result<[Transaction], RepositoryError>
    func createTransaction(amount: Double, type: String, date: Date, description: String?, category: Category) -> Result<Transaction, RepositoryError>
    func deleteTransaction(_ transaction: Transaction) -> Result<Void, RepositoryError>
    func calculateTotalIncome(from startDate: Date?, to endDate: Date?) -> Result<Double, RepositoryError>
    func calculateTotalExpenses(from startDate: Date?, to endDate: Date?) -> Result<Double, RepositoryError>
    func calculateSpending(for category: Category, from startDate: Date, to endDate: Date) -> Result<Double, RepositoryError>
}
