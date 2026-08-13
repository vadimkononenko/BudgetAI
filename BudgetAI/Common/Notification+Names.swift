//
//  Notification+Names.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import Foundation

extension Notification.Name {
    static let transactionDidAdd = Notification.Name("transactionDidAdd")
    static let transactionDidChange = Notification.Name("transactionDidChange")
    static let transactionDidDelete = Notification.Name("transactionDidDelete")
}
