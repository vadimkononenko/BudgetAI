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

    func fetchAllCategories() -> Result<[Category], CoreDataError> {
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return coreDataManager.fetch(Category.self, predicate: nil, sortDescriptors: sortDescriptors)
    }

    func fetchCategories(type: String) -> Result<[Category], CoreDataError> {
        let predicate = NSPredicate(format: "type == %@", type)
        let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return coreDataManager.fetch(Category.self, predicate: predicate, sortDescriptors: sortDescriptors)
    }

    func createCategory(name: String, colorHex: String, icon: String, type: String) -> Result<Category, CoreDataError> {
        let category = coreDataManager.create(Category.self)
        category.id = UUID()
        category.name = name
        category.colorHex = colorHex
        category.icon = icon
        category.type = type

        return coreDataManager.saveContext().map { category }
    }

    func deleteCategory(_ category: Category) -> Result<Void, CoreDataError> {
        return coreDataManager.delete(category)
    }
}
