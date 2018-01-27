//
//  YPVideoHelper.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 27/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation
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
    private var videoInput: AVCaptureDeviceInput!
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoRecordingTimeLimit: TimeInterval = 0
    
    // MARK: - Init
    
    public func initialize(withVideoRecordingLimit: TimeInterval) {
        self.videoRecordingTimeLimit = withVideoRecordingLimit
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }
    
    // MARK: - Start Camera
    
    public func startCamera() {
        if !session.isRunning {
            sessionQueue.async { [unowned self] in
                // Re-apply session preset
                self.session.sessionPreset = AVCaptureSession.Preset.high
                let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                switch status {
                case .notDetermined, .restricted, .denied:
                    self.session.stopRunning()
                case .authorized:
                    self.session.startRunning()
                }
            }
        }
    }
    
    // MARK: - Flip Camera
    
    public func flipCamera(completion: @escaping () -> Void) {
        sessionQueue.async { [unowned self] in
            self.session.beginConfiguration()
            self.session.resetInputs()
            self.videoInput = flippedDeviceInputForInput(self.videoInput)
            if self.session.canAddInput(self.videoInput) {
                self.session.addInput(self.videoInput)
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
            session.sessionPreset = AVCaptureSession.Preset.high
        }
        session.commitConfiguration()
    }
    
    // MARK: - Video Layer
    
    public func newVideoLayer() -> CALayer {
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return videoLayer
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
