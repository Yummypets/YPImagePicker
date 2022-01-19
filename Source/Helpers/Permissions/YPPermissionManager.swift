//
//  YPPermissionManager.swift
//  YPImagePicker
//
//  Created by Nik Kov on 12.08.2021.
//

import Photos
import UIKit

internal struct YPPermissionManager {
    typealias YPPermissionManagerCompletion = (_ hasPermission: Bool) -> Void

    static func checkLibraryPermissionAndAskIfNeeded(sourceVC: UIViewController,
                                                     completion: @escaping YPPermissionManagerCompletion) {
        var status: PHAuthorizationStatus

        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized:
            completion(true)
        case .limited:
            completion(true)
        case .restricted, .denied:
            let alert = YPPermissionDeniedPopup.buildGoToSettingsAlert(cancelBlock: {
                completion(false)
            })
            sourceVC.present(alert, animated: true, completion: nil)
        case .notDetermined:
            // Show permission popup and get new status
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in
                    DispatchQueue.main.async {
                        completion(s == .authorized || s == .limited)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { s in
                    DispatchQueue.main.async {
                        completion(s == .authorized)
                    }
                }
            }
        @unknown default:
            ypLog("Bug. Write to developers please.")
        }
    }

    static func checkCameraPermissionAndAskIfNeeded(sourceVC: UIViewController,
                                                    completion: @escaping YPPermissionManagerCompletion) {
        let type: AVMediaType = .video
        let status = AVCaptureDevice.authorizationStatus(for: type)

        switch status {
        case .authorized:
            completion(true)
        case .restricted, .denied:
            let alert = YPPermissionDeniedPopup.buildGoToSettingsAlert(cancelBlock: {
                completion(false)
            })
            sourceVC.present(alert, animated: true, completion: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: type) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            ypLog("Bug. Write to developers please.")
        }
    }
}
