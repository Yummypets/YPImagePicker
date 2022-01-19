//
//  AVCaptureDevice+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

// MARK: - Global functions


internal func flippedDeviceInputForInput(_ input: AVCaptureDeviceInput) -> AVCaptureDeviceInput? {
    let position: AVCaptureDevice.Position = (input.device.position == .front) ? .back : .front
    guard let aDevice = AVCaptureDevice.deviceForPosition(position) else {
        return nil
    }
    return try? AVCaptureDeviceInput(device: aDevice)
}

internal func thumbnailFromVideoPath(_ path: URL) -> UIImage {
    let asset = AVURLAsset(url: path, options: nil)
    let gen = AVAssetImageGenerator(asset: asset)
    gen.appliesPreferredTrackTransform = true
    let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
    var actualTime = CMTimeMake(value: 0, timescale: 0)
    let image: CGImage
    do {
        image = try gen.copyCGImage(at: time, actualTime: &actualTime)
        let thumbnail = UIImage(cgImage: image)
        return thumbnail
    } catch { }
    return UIImage()
}

internal func setFocusPointOnDevice(device: AVCaptureDevice, point: CGPoint) {
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

internal func setFocusPointOnCurrentDevice(_ point: CGPoint) {
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
