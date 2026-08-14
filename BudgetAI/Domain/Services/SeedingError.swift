//
//  SeedingError.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

enum SeedingError: Error {
    case fetchFailed(underlying: Error)
    case batchCreationFailed(underlying: Error)
}

extension SeedingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Не вдалося перевірити наявні категорії"
        case .batchCreationFailed:
            return "Не вдалося створити категорію"
        }
    }
}
