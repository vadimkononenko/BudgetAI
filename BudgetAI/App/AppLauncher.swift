//
//  AppLauncher.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 20.08.2026.
//

import Foundation

final class AppLauncher {
    private let seeder: DefaultCategorySeeder

    init(seeder: DefaultCategorySeeder) {
        self.seeder = seeder
    }

    func run() -> AppLaunchState {
        do {
            try seeder.seedIfNeeded()
            return .ready
        } catch {
            return .failed(error)
        }
    }
}
