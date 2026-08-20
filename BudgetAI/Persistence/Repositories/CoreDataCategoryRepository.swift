//
//  CoreDataCategoryRepository.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation
import CoreData

final class CoreDataCategoryRepository: CategoryRepository {

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    func fetchAllCategories() -> Result<[Category], RepositoryError> {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return coreDataManager.fetch(Category.self, predicate: nil, sortDescriptors: sortDescriptors)
    }

    func fetchCategories(type: String) -> Result<[Category], RepositoryError> {
        let predicate = NSPredicate(format: "type == %@", type)
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return coreDataManager.fetch(Category.self, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    func createCategory(name: String, colorHex: String, icon: String, type: String) -> Result<Category, RepositoryError> {
        let category = coreDataManager.create(Category.self)
        category.id = UUID()
        category.name = name
        category.colorHex = colorHex
        category.icon = icon
        category.type = type

        return coreDataManager.saveContext().map { category }
    }

    func createCategories(_ drafts: [CategoryDraft]) -> Result<Void, RepositoryError> {
        for draft in drafts {
            let category = coreDataManager.create(Category.self)
            category.id = UUID()
            category.name = draft.name
            category.colorHex = draft.colorHex
            category.icon = draft.icon
            category.type = draft.type
        }

        return coreDataManager.saveContext()
    }

    func deleteCategory(_ category: Category) -> Result<Void, RepositoryError> {
        return coreDataManager.delete(category)
    }
}
