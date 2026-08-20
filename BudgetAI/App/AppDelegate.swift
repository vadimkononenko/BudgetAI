//
//  AppDelegate.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            try DIContainer.shared.makeCategorySeeder().seedIfNeeded()
            print("applied version:", try! DIContainer.shared.seedVersionStore.appliedVersion())
        } catch {
            assertionFailure("Category seeding failed: \(error)")
        }
        return true
    }

}
