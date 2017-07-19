//
//  FSHelpers.swift
//  Fusuma
//
//  Created by Sacha Durand Saint Omer on 02/11/16.
//  Copyright © 2016 ytakzk. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

func fsLocalized(_ str: String) -> String {
    return NSLocalizedString(str,
                             tableName: nil,
                             bundle: Bundle(for:FusumaVC.self),
                             value: "",
                             comment: "")
}

func imageFromBundle(_ named: String) -> UIImage {
    return UIImage(named: named, in: Bundle(for:FusumaVC.self), compatibleWith: nil) ?? UIImage()
}

func deviceForPosition(_ p: AVCaptureDevicePosition) -> AVCaptureDevice? {
    for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
        if let d = device as? AVCaptureDevice, d.position == p {
            return d
        }
    }
    return nil
}

extension AVCaptureDevice {
    func tryToggleFlash() {
        guard hasFlash else { return }
        do {
            try lockForConfiguration()
            if flashMode == .off {
                flashMode = .on
            } else if flashMode == .on {
                flashMode = .off
            }
            unlockForConfiguration()
        } catch _ { }
    }
    
    func disableFlash() {
        guard hasFlash else { return }
        do {
            try lockForConfiguration()
            flashMode = .off
            unlockForConfiguration()
        } catch _ { }
    }
}

func configureFocusView(_ v: UIView) {
    v.alpha = 0.0
    v.backgroundColor = UIColor.clear
    v.layer.borderColor = fusumaBaseTintColor.cgColor
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
        if device.isFocusModeSupported(AVCaptureFocusMode.autoFocus) {
            device.focusMode = AVCaptureFocusMode.autoFocus
            device.focusPointOfInterest = point
        }
        if device.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) {
            device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = point
        }
        device.unlockForConfiguration()
    } catch _ {
        return
    }
}

func setFocusPointOnCurrentDevice(_ point: CGPoint) {
    if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(AVCaptureFocusMode.autoFocus) == true {
                device.focusMode = AVCaptureFocusMode.autoFocus
                device.focusPointOfInterest = point
            }
            if device.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) == true {
                device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
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
        for input in inputs {
            if let i = input as? AVCaptureInput {
                removeInput(i)
            }
        }
    }
}

func toggledPositionForDevice(_ device: AVCaptureDevice) -> AVCaptureDevicePosition {
   return (device.position == .front) ? .back : .front
}

func flippedDeviceInputForInput(_ input: AVCaptureDeviceInput) -> AVCaptureDeviceInput? {
    let p = toggledPositionForDevice(input.device)
    let aDevice = deviceForPosition(p)
    return try? AVCaptureDeviceInput(device: aDevice)
}

func formattedStrigFrom(_ timeInterval: TimeInterval) -> String {
    let interval = Int(timeInterval)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}
