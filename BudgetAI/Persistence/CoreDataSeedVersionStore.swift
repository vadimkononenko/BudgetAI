//
//  CoreDataSeedVersionStore.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.08.2026.
//

import Foundation
import CoreData

struct CoreDataSeedVersionStore: SeedVersionStore {
    private enum Key {
        static let categorySeedVersion = "com.budgetai.categorySeedVersion"
    }

    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }

    func appliedVersion() throws -> Int {
        let (coordinator, store) = try resolveStore()
        return coordinator.metadata(for: store)[Key.categorySeedVersion] as? Int ?? 0
    }
    
    func stageAppliedVersion(_ version: Int) throws {
        let (coordinator, store) = try resolveStore()
        var metadata = coordinator.metadata(for: store)
        metadata[Key.categorySeedVersion] = version
        coordinator.setMetadata(metadata, for: store)
    }

    private func resolveStore() throws -> (NSPersistentStoreCoordinator, NSPersistentStore) {
        let coordinator = coreDataManager.persistentContainer.persistentStoreCoordinator
        guard let store = coordinator.persistentStores.first else {
            throw RepositoryError.notInitialized
        }
        return (coordinator, store)
    }
}
