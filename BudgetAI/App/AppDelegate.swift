//
//  AppDelegate.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private(set) var launchState: AppLaunchState = .ready

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        launchState = DIContainer.shared.appLauncher.run()
        return true
    }

}
