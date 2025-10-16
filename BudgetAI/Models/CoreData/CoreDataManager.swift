//
//  CoreDataManager.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import CoreData

final class CoreDataManager {

    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "BudgetAI")

        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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

        // Создаем тестовые транзакции
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

        manager.saveContext()
        return manager
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - CRUD Operations

    func create<T: NSManagedObject>(_ type: T.Type) -> T {
        return T(context: context)
    }

    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        do {
            return try context.fetch(request) as? [T] ?? []
        } catch {
            print("Failed to fetch \(type): \(error)")
            return []
        }
    }

    func delete(_ object: NSManagedObject) {
        context.delete(object)
        saveContext()
    }
}
