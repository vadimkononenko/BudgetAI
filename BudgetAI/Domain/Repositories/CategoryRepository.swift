//
//  CategoryRepository.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

protocol CategoryRepository {
    func fetchAllCategories() -> Result<[Category], RepositoryError>
    func fetchCategories(type: String) -> Result<[Category], RepositoryError>
    func createCategory(name: String, colorHex: String, icon: String, type: String) -> Result<Category, RepositoryError>
    func deleteCategory(_ category: Category) -> Result<Void, RepositoryError>
}
