//
//  DefaultCategorySeeder.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

struct DefaultCategorySeeder {
    private let repository: CategoryRepository
    private let drafts: [CategoryDraft]

    init(
        repository: CategoryRepository,
        drafts: [CategoryDraft] = DefaultCategories.all
    ) {
        self.repository = repository
        self.drafts = drafts
    }

    func seedIfNeeded() throws {
        let existingCategories: [Category]

        switch repository.fetchAllCategories() {
        case .success(let categories):
            existingCategories = categories
        case .failure(let error):
            throw SeedingError.fetchFailed(underlying: error)
        }

        guard existingCategories.isEmpty else { return }

        if case .failure(let error) = repository.createCategories(drafts) {
            throw SeedingError.batchCreationFailed(underlying: error)
        }
    }
}
