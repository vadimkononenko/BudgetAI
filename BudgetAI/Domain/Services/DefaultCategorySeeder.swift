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

        for draft in drafts {
            let result = repository.createCategory(
                name: draft.name,
                colorHex: draft.colorHex,
                icon: draft.icon,
                type: draft.type
            )

            if case .failure(let error) = result {
                throw SeedingError.creationFailed(
                    draft: draft,
                    underlying: error
                )
            }
        }
    }
}
