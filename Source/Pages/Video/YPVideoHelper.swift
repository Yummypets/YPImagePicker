//
//  YPVideoHelper.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 27/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

/// Abstracts Low Level AVFoudation details.
class YPVideoHelper: NSObject {
    
    public var isRecording: Bool { return videoOutput.isRecording }
    public var didCaptureVideo: ((URL) -> Void)?
    public var videoRecordingProgress: ((Float, TimeInterval) -> Void)?
    
    private let session = AVCaptureSession()
    private var timer = Timer()
    private var dateVideoStarted = Date()
    private let sessionQueue = DispatchQueue(label: "YPVideoVCSerialQueue")
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoRecordingTimeLimit: TimeInterval = 0
    private var isCaptureSessionSetup: Bool = false
    private var isPreviewSetup = false
    private var previewView: UIView!
    
    // MARK: - Init
    
    public func start(previewView: UIView, withVideoRecordingLimit: TimeInterval, completion: @escaping () -> Void) {
        self.previewView = previewView
        self.videoRecordingTimeLimit = withVideoRecordingLimit
        sessionQueue.async { [unowned self] in
            if !self.isCaptureSessionSetup {
                self.setupCaptureSession()
            }
            self.startCamera(completion: {
                completion()
            })
        }
    }
    
    // MARK: - Start Camera
    
    public func startCamera(completion: @escaping (() -> Void)) {
        if !session.isRunning {
            sessionQueue.async { [weak self] in
                // Re-apply session preset
                self?.session.sessionPreset = .high
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
    
    // MARK: - Flip Camera
    
    public func flipCamera(completion: @escaping () -> Void) {
        sessionQueue.async { [unowned self] in
            self.session.beginConfiguration()
            self.session.resetInputs()
            
            if let videoInput = self.videoInput {
                self.videoInput = flippedDeviceInputForInput(videoInput)
            }
            
            if let videoInput = self.videoInput {
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                }
            }
            
            // Re Add audio recording
            for device in AVCaptureDevice.devices(for: .audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: device) {
                    if self.session.canAddInput(audioInput) {
                        self.session.addInput(audioInput)
                    }
                }
            }
            self.session.commitConfiguration()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Focus
    
    public func focus(onPoint point: CGPoint) {
        setFocusPointOnDevice(device: videoInput!.device, point: point)
    }
    
    // MARK: - Stop Camera
    
    public func stopCamera() {
        if session.isRunning {
            sessionQueue.async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    // MARK: - Torch
    
    public func hasTorch() -> Bool {
        return videoInput?.device.hasTorch ?? false
    }
    
    public func currentTorchMode() -> AVCaptureDevice.TorchMode {
        guard let device = videoInput?.device else {
            return .off
        }
        if !device.hasTorch {
            return .off
        }
        return device.torchMode
    }
    
    public func toggleTorch() {
        videoInput?.device.tryToggleTorch()
    }
    
    // MARK: - Recording
    
    public func startRecording() {
        let outputPath = "\(NSTemporaryDirectory())output.mov"
        let outputURL = URL(fileURLWithPath: outputPath)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputPath) {
            do {
                try fileManager.removeItem(atPath: outputPath)
            } catch {
                return
            }
        }
        
        let connection = videoOutput.connection(with: .video)
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = currentVideoOrientation()
        }
        
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    public func stopRecording() {
        videoOutput.stopRecording()
    }
    
    // Private
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        let aDevice = deviceForPosition(.back)
        if let d = aDevice {
            videoInput = try? AVCaptureDeviceInput(device: d)
        }
        
        if let videoInput = videoInput {
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // Add audio recording
            for device in AVCaptureDevice.devices(for: .audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: device) {
                    if session.canAddInput(audioInput) {
                        session.addInput(audioInput)
                    }
                }
            }
            
            let timeScale: Int32 = 30 // FPS
            let maxDuration =
                CMTimeMakeWithSeconds(self.videoRecordingTimeLimit, timeScale)
            videoOutput.maxRecordedDuration = maxDuration
            videoOutput.minFreeDiskSpaceLimit = 1024 * 1024
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            session.sessionPreset = .high
        }
        session.commitConfiguration()
        isCaptureSessionSetup = true
    }
    
    // MARK: - Recording Progress
    
    @objc
    func tick() {
        let timeElapsed = Date().timeIntervalSince(dateVideoStarted)
        let progress: Float = Float(timeElapsed) / Float(videoRecordingTimeLimit)
        DispatchQueue.main.async {
            self.videoRecordingProgress?(progress, timeElapsed)
        }
    }
    
    // MARK: - Orientation
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .landscapeRight
        }
        return orientation
    }

    // MARK: - Preview
    
    func tryToSetupPreview() {
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
    }
    
    func setupPreview() {
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async {
            videoLayer.frame = self.previewView.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.previewView.layer.addSublayer(videoLayer)
        }
    }
}

extension YPVideoHelper: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput,
                           didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection]) {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(tick),
                                     userInfo: nil,
                                     repeats: true)
        dateVideoStarted = Date()
    }
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        didCaptureVideo?(outputFileURL)
        timer.invalidate()
    }
}
