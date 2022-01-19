//
//  YPVideoHelper.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 27/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

/// Abstracts Low Level AVFoudation details.
class YPVideoCaptureHelper: NSObject {
    public var isRecording: Bool {
        return videoOutput.isRecording
    }
    public var didCaptureVideo: ((URL) -> Void)?
    public var videoRecordingProgress: ((Float, TimeInterval) -> Void)?
    
    private let session = AVCaptureSession()
    private var timer = Timer()
    private var dateVideoStarted = Date()
    private let sessionQueue = DispatchQueue(label: "YPVideoCaptureHelperQueue")
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoRecordingTimeLimit: TimeInterval = 0
    private var isCaptureSessionSetup: Bool = false
    private var isPreviewSetup = false
    private var previewView: UIView!
    private var motionManager = CMMotionManager()
    private var initVideoZoomFactor: CGFloat = 1.0
    
    // MARK: - Init
    
    public func start(previewView: UIView, withVideoRecordingLimit: TimeInterval, completion: @escaping () -> Void) {
        self.previewView = previewView
        self.videoRecordingTimeLimit = withVideoRecordingLimit
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
    
    // MARK: - Start Camera
    
    public func startCamera(completion: @escaping (() -> Void)) {
        guard !session.isRunning else {
            print("Session is already running. Returning.")
            return
        }

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
            @unknown default:
                ypLog("unknown default reached. Check code.")
            }
        }
    }
    
    // MARK: - Flip Camera
    
    public func flipCamera(completion: @escaping () -> Void) {
        sessionQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.session.beginConfiguration()
            strongSelf.session.resetInputs()
            
            if let videoInput = strongSelf.videoInput {
                strongSelf.videoInput = flippedDeviceInputForInput(videoInput)
            }
            
            if let videoInput = strongSelf.videoInput {
                if strongSelf.session.canAddInput(videoInput) {
                    strongSelf.session.addInput(videoInput)
                }
            }
            
            // Re Add audio recording
            if let audioDevice = AVCaptureDevice.audioCaptureDevice,
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               strongSelf.session.canAddInput(audioInput) {
                strongSelf.session.addInput(audioInput)
            }

            strongSelf.session.commitConfiguration()

            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Focus
    
    public func focus(onPoint point: CGPoint) {
        if let device = videoInput?.device {
            setFocusPointOnDevice(device: device, point: point)
        }
    }
    
    // MARK: - Zoom
    
    public func zoom(began: Bool, scale: CGFloat) {
        guard let device = videoInput?.device else {
            return
        }

        if began {
            initVideoZoomFactor = device.videoZoomFactor
            return
        }

        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            var minAvailableVideoZoomFactor: CGFloat = 1.0
            if #available(iOS 11.0, *) {
                minAvailableVideoZoomFactor = device.minAvailableVideoZoomFactor
            }
            var maxAvailableVideoZoomFactor: CGFloat = device.activeFormat.videoMaxZoomFactor
            if #available(iOS 11.0, *) {
                maxAvailableVideoZoomFactor = device.maxAvailableVideoZoomFactor
            }
            maxAvailableVideoZoomFactor = min(maxAvailableVideoZoomFactor, YPConfig.maxCameraZoomFactor)

            let desiredZoomFactor = initVideoZoomFactor * scale
            device.videoZoomFactor = max(minAvailableVideoZoomFactor,
                                         min(desiredZoomFactor, maxAvailableVideoZoomFactor))
        } catch let error {
            ypLog("Error: \(error)")
        }
    }
    
    // MARK: - Stop Camera
    
    public func stopCamera() {
        guard session.isRunning else {
            return
        }

        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
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
        let outputURL = YPVideoProcessor.makeVideoPathURL(temporaryFolder: true, fileName: "recordedVideoRAW")

        checkOrientation { [weak self] orientation in
            guard let strongSelf = self else {
                return
            }
            if let connection = strongSelf.videoOutput.connection(with: .video) {
                if let orientation = orientation, connection.isVideoOrientationSupported {
                    connection.videoOrientation = orientation
                }
                strongSelf.videoOutput.startRecording(to: outputURL, recordingDelegate: strongSelf)
            }
        }
    }
    
    public func stopRecording() {
        videoOutput.stopRecording()
    }
    
    // Private
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        let cameraPosition: AVCaptureDevice.Position = YPConfig.usesFrontCamera ? .front : .back
        let aDevice = AVCaptureDevice.deviceForPosition(cameraPosition)
        
        if let d = aDevice {
            videoInput = try? AVCaptureDeviceInput(device: d)
        }
        
        if let videoInput = videoInput {
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // Add audio recording
            if let audioDevice = AVCaptureDevice.audioCaptureDevice,
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }

            let timeScale: Int32 = 30 // FPS
            let maxDuration =
                CMTimeMakeWithSeconds(self.videoRecordingTimeLimit, preferredTimescale: timeScale)
            videoOutput.maxRecordedDuration = maxDuration
            if let sizeLimit = YPConfig.video.recordingSizeLimit {
                videoOutput.maxRecordedFileSize = sizeLimit
            }
            videoOutput.minFreeDiskSpaceLimit = YPConfig.video.minFreeDiskSpaceLimit
            if YPConfig.video.fileType == .mp4,
               YPConfig.video.recordingSizeLimit != nil {
                videoOutput.movieFragmentInterval = .invalid // Allows audio for MP4s over 10 seconds.
            }
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
        var progress: Float
        if let recordingSizeLimit = YPConfig.video.recordingSizeLimit {
            progress = Float(videoOutput.recordedFileSize) / Float(recordingSizeLimit)
        } else {
            progress = Float(timeElapsed) / Float(videoRecordingTimeLimit)
        }
        // VideoOutput configuration is responsible for stopping the recording. Not here.
        DispatchQueue.main.async {
            self.videoRecordingProgress?(progress, timeElapsed)
        }
    }
    
    // MARK: - Orientation

    /// This enables to get the correct orientation even when the device is locked for orientation \o/
    private func checkOrientation(completion: @escaping(_ orientation: AVCaptureVideoOrientation?) -> Void) {
        motionManager.accelerometerUpdateInterval = 5
        motionManager.startAccelerometerUpdates( to: OperationQueue() ) { [weak self] data, _ in
            self?.motionManager.stopAccelerometerUpdates()
            guard let data = data else {
                completion(nil)
                return
            }
            let orientation: AVCaptureVideoOrientation = abs(data.acceleration.y) < abs(data.acceleration.x)
                ? data.acceleration.x > 0 ? .landscapeLeft : .landscapeRight
                : data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
            DispatchQueue.main.async {
                completion(orientation)
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
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async {
            videoLayer.frame = self.previewView.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.previewView.layer.addSublayer(videoLayer)
        }
    }
}

extension YPVideoCaptureHelper: AVCaptureFileOutputRecordingDelegate {
    
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
        if let error = error {
            ypLog("Error: \(error)")
        }

        if YPConfig.onlySquareImagesFromCamera {
            YPVideoProcessor.cropToSquare(filePath: outputFileURL) { [weak self] url in
                guard let _self = self, let u = url else { return }
                _self.didCaptureVideo?(u)
            }
        } else {
            self.didCaptureVideo?(outputFileURL)
        }
        timer.invalidate()
    }
}
