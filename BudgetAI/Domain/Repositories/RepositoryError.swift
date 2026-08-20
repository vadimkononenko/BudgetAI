//
//  RepositoryError.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.08.2026.
//

import Foundation

enum RepositoryError: Error, LocalizedError {
    case failedToLoad(Error)
    case failedToSave(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .failedToLoad(let error):
            return "Не вдалося завантажити базу даних: \(error.localizedDescription)"
        case .failedToSave(let error):
            return "Не вдалося зберегти дані: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Не вдалося отримати дані: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Не вдалося видалити дані: \(error.localizedDescription)"
        case .notInitialized:
            return "База даних не ініціалізована"
        }
    }
}
