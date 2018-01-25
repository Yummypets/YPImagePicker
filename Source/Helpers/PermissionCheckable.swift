//
//  PermissionCheckable.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 25/01/2018.
//  Copyright © 2018 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation

protocol PermissionCheckable {
    func checkPermission()
}

extension PermissionCheckable where Self: UIViewController {
    
    func checkPermission() {
        checkPermissionToAccessVideo { _ in }
    }
    
    func doAfterPermissionCheck(block:@escaping () -> Void) {
        checkPermissionToAccessVideo { hasPermission in
            if hasPermission {
                block()
            }
        }
    }
    
    // Async beacause will prompt permission if .notDetermined
    // and ask custom popup if denied.
    func checkPermissionToAccessVideo(block: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            block(true)
        case .restricted, .denied:
            let alert = YPPermissionDeniedPopup.popup(cancelBlock: {
                block(false)
            })
            present(alert, animated: true, completion: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    block(granted)
                }
            })
        }
    }
}
