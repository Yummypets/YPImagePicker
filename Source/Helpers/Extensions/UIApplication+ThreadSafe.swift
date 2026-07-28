//
//  UIApplication+ThreadSafe.swift
//  YPImagePicker
//
//  Created by GitHub Copilot on 09/07/2025.
//  Copyright © 2025 Yummypets. All rights reserved.
//

import UIKit

extension UIApplication {
    /// Thread-safe access to connected scenes
    static var safeConnectedScenes: Set<UIScene> {
        if Thread.isMainThread {
            return UIApplication.shared.connectedScenes
        } else {
            return DispatchQueue.main.sync {
                return UIApplication.shared.connectedScenes
            }
        }
    }
    
    /// Thread-safe access to the first window scene
    static var safeFirstWindowScene: UIWindowScene? {
        return safeConnectedScenes.first as? UIWindowScene
    }

    /// Thread-safe access to the first window scene's screen width.
    /// `-[UIWindowScene screen]` must be read on the main thread.
    static var safeFirstWindowScreenWidth: CGFloat? {
        let read: () -> CGFloat? = {
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width
        }
        return Thread.isMainThread ? read() : DispatchQueue.main.sync(execute: read)
    }
}
