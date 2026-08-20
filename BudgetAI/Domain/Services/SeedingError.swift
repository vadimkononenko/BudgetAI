//
//  SeedingError.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

enum SeedingError: Error {
    case fetchFailed(underlying: Error)
    case batchCreationFailed(version: Int, underlying: Error)
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

extension SeedingError: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .fetchFailed(let underlying):
            return "fetchFailed — \(underlying)"
        case .batchCreationFailed(let version, let underlying):
            return "batchCreationFailed(version: \(version)) — \(underlying)"
        }
    }
}
