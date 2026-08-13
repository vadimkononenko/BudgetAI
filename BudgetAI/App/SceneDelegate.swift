//
//  SceneDelegate.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        // Use DIContainer to create MainTabBarController with all dependencies
        window?.rootViewController = DIContainer.shared.makeMainTabBarController()
        window?.makeKeyAndVisible()
    }
}

