//
//  SeedingError.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 13.08.2026.
//

import Foundation

enum SeedingError: Error {
    case fetchFailed(underlying: Error)
    case creationFailed(draft: CategoryDraft, underlying: Error)
}

extension SeedingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Не вдалося перевірити наявні категорії"
        case .creationFailed(let draft, _):
            return "Не вдалося створити категорію \"\(draft.name)\""
        }
    }
}
