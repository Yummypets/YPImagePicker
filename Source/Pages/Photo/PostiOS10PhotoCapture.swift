//
//  PostiOS10PhotoCapture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 08/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 10.0, *)
class PostiOS10PhotoCapture: NSObject, YPPhotoCapture, AVCapturePhotoCaptureDelegate {

    let sessionQueue = DispatchQueue(label: "YPCameraVCSerialQueue", qos: .background)
    let session = AVCaptureSession()
    var deviceInput: AVCaptureDeviceInput?
    var device: AVCaptureDevice? { return deviceInput?.device }
    private let photoOutput = AVCapturePhotoOutput()
    var output: AVCaptureOutput { return photoOutput }
    var isCaptureSessionSetup: Bool = false
    var isPreviewSetup: Bool = false
    var previewView: UIView!
    var videoLayer: AVCaptureVideoPreviewLayer!
    var currentFlashMode: YPFlashMode = .off
    var hasFlash: Bool {
        guard let device = device else { return false }
        return device.hasFlash
    }
    var block: ((Data) -> Void)?
    var initVideoZoomFactor: CGFloat = 1.0
    
    // MARK: - Configuration
    
    private func newSettings() -> AVCapturePhotoSettings {
        var settings = AVCapturePhotoSettings()
        
        // Catpure Heif when available.
        if #available(iOS 11.0, *) {
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        
        // Catpure Highest Quality possible.
        settings.isHighResolutionPhotoEnabled = true
        
        // Set flash mode.
        if let deviceInput = deviceInput {
            if deviceInput.device.isFlashAvailable {
                switch currentFlashMode {
                case .auto:
                    if photoOutput.supportedFlashModes.contains(.auto) {
                        settings.flashMode = .auto
                    }
                case .off:
                    if photoOutput.supportedFlashModes.contains(.off) {
                        settings.flashMode = .off
                    }
                case .on:
                    if photoOutput.supportedFlashModes.contains(.on) {
                        settings.flashMode = .on
                    }
                }
            }
        }
        return settings
    }
    
    func configure() {
        photoOutput.isHighResolutionCaptureEnabled = true
        
        // Improve capture time by preparing output with the desired settings.
        photoOutput.setPreparedPhotoSettingsArray([newSettings()], completionHandler: nil)
    }
    
    // MARK: - Flash
    
    func tryToggleFlash() {
        // if device.hasFlash device.isFlashAvailable //TODO test these
        switch currentFlashMode {
        case .auto:
            currentFlashMode = .on
        case .on:
            currentFlashMode = .off
        case .off:
            currentFlashMode = .auto
        }
    }
    
    // MARK: - Shoot

    func shoot(completion: @escaping (Data) -> Void) {
        block = completion
    
        // Set current device orientation
        setCurrentOrienation()
        
        let settings = newSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        block?(data)
    }
        
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        guard let buffer = photoSampleBuffer else { return }
        if let data = AVCapturePhotoOutput
            .jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer,
                                         previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
            block?(data)
        }
    }
}
