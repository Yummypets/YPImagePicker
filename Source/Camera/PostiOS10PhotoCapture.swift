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
    
    private let photoOutput = AVCapturePhotoOutput()
    var block: ((Data) -> Void)?
    var currentFlashMode: YPFlashMode = .off
    var previewView: UIView!
    var isPreviewSetup: Bool = false
    var videoLayer: AVCaptureVideoPreviewLayer!
    
    
    var output: AVCaptureOutput { return photoOutput }
    var deviceInput: AVCaptureDeviceInput!
    var device: AVCaptureDevice? { return deviceInput.device }
    let sessionQueue = DispatchQueue(label: "YPCameraVCSerialQueue", qos: .background)
    let session = AVCaptureSession()
    
    var hasFlash: Bool {
        guard let device = device else { return false }
        return device.hasFlash
    }
    
    func setup(with previewView: UIView) {
        self.previewView = previewView
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }
    
    func focus(on point: CGPoint) {
        setFocusPointOnDevice(device: device!, point: point)
    }
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        let cameraPosition: AVCaptureDevice.Position = .back
        
        //TODO self.configuration.usesFrontCamera ? .front : .back
        let aDevice = deviceForPosition(cameraPosition)
        if let d = aDevice {
            deviceInput = try? AVCaptureDeviceInput(device: d)
        }
        if let videoInput = deviceInput {
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            if session.canAddOutput(output) {
                session.addOutput(output)
                configure()
            }
        }
        session.commitConfiguration()
    }
    
    func tryToggleFlash() {
        //        if device.hasFlash device.isFlashAvailable //TODO test these
        switch currentFlashMode {
        case .auto:
            currentFlashMode = .on
        case .on:
            currentFlashMode = .off
        case .off:
            currentFlashMode = .auto
        }
    }
    
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
        if deviceInput.device.isFlashAvailable {
            switch currentFlashMode {
            case .auto:
                if photoOutput.supportedFlashModes.contains(.auto) {
                    settings.flashMode = .auto
                } else {
                    print("NOPE")
                }
            case .off:
                if photoOutput.supportedFlashModes.contains(.off) {
                    settings.flashMode = .off
                } else {
                    print("NOPE")
                }
            case .on:
                if photoOutput.supportedFlashModes.contains(.on) {
                    settings.flashMode = .on
                } else {
                    print("NOPE")
                }
            }
        }
        return settings
    }

    func shoot(completion: @escaping (Data) -> Void) {
        block = completion
    
        // Set current device orientation
        setCurrentOrienation()
        
        let settings = newSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func configure() {
        photoOutput.isHighResolutionCaptureEnabled = true
        
        // Improve capture time by preparing output with the desired settings.
        photoOutput.setPreparedPhotoSettingsArray([newSettings()], completionHandler: nil)
    }

    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto")
        if let data = photo.fileDataRepresentation() {
            
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
            bcf.countStyle = .file
            let string = bcf.string(fromByteCount: Int64(data.count))
            print("formatted result: \(string)")
            
            block?(data)
        }
    }
}

