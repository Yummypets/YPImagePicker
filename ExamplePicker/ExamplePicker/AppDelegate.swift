//
//  AppDelegate.swift
//  ExamplePicker
//
//  Created by Sacha DSO on 28/09/2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ExampleViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

