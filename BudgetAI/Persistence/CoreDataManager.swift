//
//  CoreDataManager.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import CoreData

// MARK: - CoreDataManager

final class CoreDataManager {

    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer
    private(set) var isInitialized: Bool = false
    private(set) var initializationError: RepositoryError?

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "BudgetAI")

        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable automatic migrations
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        persistentContainer.loadPersistentStores { [weak self] description, error in
            guard let self = self else { return }

            if let error = error {
                self.initializationError = .failedToLoad(error)
                self.isInitialized = false

                // Try to setup in-memory store as fallback
                self.setupInMemoryStoreFallback()
            } else {
                self.isInitialized = true
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private func setupInMemoryStoreFallback() {
        let inMemoryContainer = NSPersistentContainer(name: "BudgetAI")
        inMemoryContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")

        inMemoryContainer.loadPersistentStores { [weak self] _, error in
            if error == nil {
                self?.isInitialized = true
            }
        }
    }

    static func preview() -> CoreDataManager {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.context

        // mocking data
        let foodCategory = Category(context: context)
        foodCategory.id = UUID()
        foodCategory.name = "Їжа"
        foodCategory.colorHex = "#FF6B6B"
        foodCategory.icon = "🍔"
        foodCategory.type = "expense"

        let transportCategory = Category(context: context)
        transportCategory.id = UUID()
        transportCategory.name = "Транспорт"
        transportCategory.colorHex = "#4ECDC4"
        transportCategory.icon = "🚗"
        transportCategory.type = "expense"

        let salaryCategory = Category(context: context)
        salaryCategory.id = UUID()
        salaryCategory.name = "Зарплата"
        salaryCategory.colorHex = "#95E1D3"
        salaryCategory.icon = "💰"
        salaryCategory.type = "income"

        let transaction1 = Transaction(context: context)
        transaction1.id = UUID()
        transaction1.amount = 150.0
        transaction1.date = Date()
        transaction1.createdAt = Date()
        transaction1.type = "expense"
        transaction1.transactionDescription = "Обід в ресторані"
        transaction1.category = foodCategory

        let transaction2 = Transaction(context: context)
        transaction2.id = UUID()
        transaction2.amount = 50.0
        transaction2.date = Date().addingTimeInterval(-86400)
        transaction2.createdAt = Date().addingTimeInterval(-86400)
        transaction2.type = "expense"
        transaction2.transactionDescription = "Таксі"
        transaction2.category = transportCategory

        let transaction3 = Transaction(context: context)
        transaction3.id = UUID()
        transaction3.amount = 5000.0
        transaction3.date = Date().addingTimeInterval(-172800)
        transaction3.createdAt = Date().addingTimeInterval(-172800)
        transaction3.type = "income"
        transaction3.transactionDescription = "Місячна зарплата"
        transaction3.category = salaryCategory

        _ = manager.saveContext()
        return manager
    }

    func saveContext() -> Result<Void, RepositoryError> {
        guard isInitialized else {
            return .failure(.notInitialized)
        }

        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return .success(())
        }

        do {
            try context.save()
            return .success(())
        } catch {
            print("❌ Failed to save context: \(error.localizedDescription)")
            context.rollback()
            return .failure(.failedToSave(error))
        }
    }

    // MARK: - CRUD Operations

    func create<T: NSManagedObject>(_ type: T.Type) -> T {
        return T(context: context)
    }

    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> Result<[T], RepositoryError> {
        guard isInitialized else {
            return .failure(.notInitialized)
        }

        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        do {
            let results = try context.fetch(request) as? [T] ?? []
            return .success(results)
        } catch {
            print("❌ Failed to fetch \(String(describing: type)): \(error.localizedDescription)")
            return .failure(.fetchFailed(error))
        }
    }

    func delete(_ object: NSManagedObject) -> Result<Void, RepositoryError> {
        guard isInitialized else {
            return .failure(.notInitialized)
        }

        context.delete(object)
        return saveContext()
    }
}
