//
//  PermissionCheckable.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 25/01/2018.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit

internal protocol YPPermissionCheckable {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void)
    func doAfterCameraPermissionCheck(block: @escaping () -> Void)
    func doAfterMicrophonePermissionCheck(block: @escaping () -> Void)
    func checkLibraryPermission()
    func checkCameraPermission()
    func checkMicrophonePermission()
}

internal extension YPPermissionCheckable where Self: UIViewController {
    func doAfterLibraryPermissionCheck(block: @escaping () -> Void) {
        YPPermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                ypLog("Not enough permissions.")
            }
        }
    }

    func doAfterCameraPermissionCheck(block: @escaping () -> Void) {
        YPPermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                ypLog("Not enough permissions.")
            }
        }
    }

    func doAfterMicrophonePermissionCheck(block: @escaping () -> Void) {
        YPPermissionManager.checkMicrophonePermissionAndAskIfNeeded(sourceVC: self) { hasPermission in
            if hasPermission {
                block()
            } else {
                ypLog("Not enough permissions.")
            }
        }
    }

    func checkLibraryPermission() {
        YPPermissionManager.checkLibraryPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
    
    func checkCameraPermission() {
        YPPermissionManager.checkCameraPermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }

    func checkMicrophonePermission() {
        YPPermissionManager.checkMicrophonePermissionAndAskIfNeeded(sourceVC: self) { _ in }
    }
}
