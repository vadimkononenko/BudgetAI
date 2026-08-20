//
//  DefaultCategorySeeder.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

struct DefaultCategorySeeder {
    private let repository: CategoryRepository
    private let versionStore: SeedVersionStore
    private let versions: [Int: [CategoryDraft]]

    init(
        repository: CategoryRepository,
        versionStore: SeedVersionStore,
        versions: [Int : [CategoryDraft]] = DefaultCategories.versions
    ) {
        self.repository = repository
        self.versionStore = versionStore
        self.versions = versions
    }

    func seedIfNeeded() throws {
        let appliedVersion = try resolveAppliedVersion()
        let pendingVersions = versions.keys.filter { $0 > appliedVersion }.sorted()

        for version in pendingVersions {
            guard let drafts = versions[version], !drafts.isEmpty else {
                continue
            }

            try versionStore.stageAppliedVersion(version)

            if case .failure(let error) = repository.createCategories(drafts) {
                try? versionStore.stageAppliedVersion(appliedVersion)
                throw SeedingError.batchCreationFailed(version: version, underlying: error)
            }
        }
    }

    private func resolveAppliedVersion() throws -> Int {
        let storedVersion = try versionStore.appliedVersion()
        guard storedVersion == 0 else {
            return storedVersion
        }

        switch repository.fetchAllCategories() {
        case .success(let categories):
            return categories.isEmpty ? 0 : 1
        case .failure(let error):
            throw SeedingError.fetchFailed(underlying: error)
        }
    }
}
