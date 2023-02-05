//
//  AppDelegate.swift
//  YPIPExample
//
//  Created by Nik Kov on 19.09.2021.
//  Copyright © 2021 Yummypets. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ExampleViewController()
        window?.makeKeyAndVisible()
        return true
    }
}
