//
//  SeedVersionStore.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.08.2026.
//

import Foundation

protocol SeedVersionStore {
    func appliedVersion() throws -> Int
    func stageAppliedVersion(_ version: Int) throws
}
