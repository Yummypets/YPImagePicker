//
//  YPPhotoCaptureDefaults.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 08/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

extension YPPhotoCapture {
    
    // MARK: - Setup
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        let cameraPosition: AVCaptureDevice.Position = YPConfig.usesFrontCamera ? .front : .back
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
        isCaptureSessionSetup = true
    }
    
    // MARK: - Start/Stop Camera
    
    func start(with previewView: UIView, completion: @escaping () -> Void) {
        self.previewView = previewView
        sessionQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if !strongSelf.isCaptureSessionSetup {
                strongSelf.setupCaptureSession()
            }
            strongSelf.startCamera(completion: {
                completion()
            })
        }
    }
    
    func startCamera(completion: @escaping (() -> Void)) {
        if !session.isRunning {
            sessionQueue.async { [weak self] in
                // Re-apply session preset
                self?.session.sessionPreset = .photo
                let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                switch status {
                case .notDetermined, .restricted, .denied:
                    self?.session.stopRunning()
                case .authorized:
                    self?.session.startRunning()
                    completion()
                    self?.tryToSetupPreview()
                }
            }
        }
    }
    
    func stopCamera() {
        if session.isRunning {
            sessionQueue.async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    // MARK: - Preview
    
    func tryToSetupPreview() {
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
    }
    
    func setupPreview() {
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async {
            self.videoLayer.frame = self.previewView.bounds
            self.videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.previewView.layer.addSublayer(self.videoLayer)
        }
    }
    
    // MARK: - Focus
    
    func focus(on point: CGPoint) {
        setFocusPointOnDevice(device: device!, point: point)
    }
    
    // MARK: - Flip
    
    func flipCamera() {
        sessionQueue.async { [weak self] in
            self?.flip()
        }
    }
    
    private func flip() {
        session.resetInputs()
        guard let di = deviceInput else { return }
        deviceInput = flippedDeviceInputForInput(di)
        guard let deviceInput = deviceInput else { return }
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
    }
    
    // MARK: - Orientation
    
    func setCurrentOrienation() {
        let connection = output.connection(with: .video)
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .portrait:
            connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection?.videoOrientation = .portraitUpsideDown
        case .landscapeRight:
            connection?.videoOrientation = .landscapeLeft
        case .landscapeLeft:
            connection?.videoOrientation = .landscapeRight
        default:
            connection?.videoOrientation = .portrait
        }
    }
}
