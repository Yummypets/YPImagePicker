//
//  YPHelpers.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 02/11/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

func ypLocalized(_ str: String) -> String {
    return NSLocalizedString(str,
                             tableName: nil,
                             bundle: Bundle(for: YPPickerVC.self),
                             value: "",
                             comment: "")
}

func imageFromBundle(_ named: String) -> UIImage {
    return UIImage(named: named, in: Bundle(for: YPPickerVC.self), compatibleWith: nil) ?? UIImage()
}

func deviceForPosition(_ p: AVCaptureDevice.Position) -> AVCaptureDevice? {
    for device in AVCaptureDevice.devices(for: AVMediaType.video) where device.position == p {
        return device
    }
    return nil
}

extension AVCaptureDevice {
//    func tryToggleFlash() {
//        guard hasFlash else { return }
//        do {
//            try lockForConfiguration()
//            switch flashMode {
//            case .auto:
//                flashMode = .on
//            case .on:
//                flashMode = .off
//            case .off:
//                flashMode = .auto
//            }
//            unlockForConfiguration()
//        } catch _ { }
//    }
//    
    func tryToggleTorch() {
        guard hasFlash else { return }
        do {
            try lockForConfiguration()
            switch torchMode {
            case .auto:
                torchMode = .on
            case .on:
                torchMode = .off
            case .off:
                torchMode = .auto
            }
            unlockForConfiguration()
        } catch _ { }
    }
}

func configureFocusView(_ v: UIView) {
    v.alpha = 0.0
    v.backgroundColor = UIColor.clear
    v.layer.borderColor = UIColor(r: 204, g: 204, b: 204).cgColor
    v.layer.borderWidth = 1.0
    v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
}

func animateFocusView(_ v: UIView) {
    UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn,
                   animations: {
                    v.alpha = 1.0
                    v.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            v.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            v.removeFromSuperview()
    })
}

func setFocusPointOnDevice(device: AVCaptureDevice, point: CGPoint) {
    do {
        try device.lockForConfiguration()
        if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
            device.focusMode = AVCaptureDevice.FocusMode.autoFocus
            device.focusPointOfInterest = point
        }
        if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = point
        }
        device.unlockForConfiguration()
    } catch _ {
        return
    }
}

func setFocusPointOnCurrentDevice(_ point: CGPoint) {
    if let device = AVCaptureDevice.default(for: AVMediaType.video) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) == true {
                device.focusMode = AVCaptureDevice.FocusMode.autoFocus
                device.focusPointOfInterest = point
            }
            if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) == true {
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                device.exposurePointOfInterest = point
            }
        } catch _ {
            return
        }
        device.unlockForConfiguration()
    }
}

extension AVCaptureSession {

    func resetInputs() {
        // remove all sesison inputs
        for i in inputs {
            removeInput(i)
        }
    }
}

func toggledPositionForDevice(_ device: AVCaptureDevice) -> AVCaptureDevice.Position {
   return (device.position == .front) ? .back : .front
}

func flippedDeviceInputForInput(_ input: AVCaptureDeviceInput) -> AVCaptureDeviceInput? {
    let p = toggledPositionForDevice(input.device)
    let aDevice = deviceForPosition(p)
    return try? AVCaptureDeviceInput(device: aDevice!)
}

func formattedStrigFrom(_ timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

extension AVPlayer {
    func togglePlayPause() {
        if rate == 0 {
            play()
        } else {
            pause()
        }
    }
}
