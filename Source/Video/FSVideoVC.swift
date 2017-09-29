//
//  FSVideoVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

public class FSVideoVC: UIViewController {
    
    public var didCaptureVideo: ((URL) -> Void)?
    private let sessionQueue = DispatchQueue(label: "FSVideoVCSerialQueue")
    let session = AVCaptureSession()
    var device: AVCaptureDevice? {
        return videoInput?.device
    }
    fileprivate var videoInput: AVCaptureDeviceInput!
    fileprivate var videoOutput = AVCaptureMovieFileOutput()
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    fileprivate var timer = Timer()
    fileprivate var dateVideoStarted = Date()
    fileprivate var v = FSCameraView()
    var isPreviewSetup = false
    
    override public func loadView() { view = v }
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        title = fsLocalized("YPImagePickerVideo")
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.flashButton.isHidden = true
        v.timeElapsedLabel.isHidden = false
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
        refreshFlashButton()
    }
    
    func setupPreview() {
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = v.previewViewContainer.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        v.previewViewContainer.layer.addSublayer(videoLayer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(focus(_:)))
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
    }
    
    func setupButtons() {
        let flipImage = imageFromBundle("yp_iconLoop")
        videoStartImage = imageFromBundle("yp_iconVideoCapture")
        videoStopImage = imageFromBundle("yp_iconVideoCaptureRecording")
        v.flashButton.setImage(flashOffImage, for: .normal)
        v.flipButton.setImage(flipImage, for: .normal)
        v.shotButton.setImage(videoStartImage, for: .normal)
    }
    
    fileprivate var isRecording = false
    
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
            for device in AVCaptureDevice.devices(for:AVMediaType.audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: device) {
                    if session.canAddInput(audioInput) {
                        session.addInput(audioInput)
                    }
                }
            }
            
            let totalSeconds = 30.0 //Total Seconds of capture time
            let timeScale: Int32 = 30 //FPS
            let maxDuration = CMTimeMakeWithSeconds(totalSeconds, timeScale)
            videoOutput.maxRecordedDuration = maxDuration
            videoOutput.minFreeDiskSpaceLimit = 1024 * 1024
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            session.sessionPreset = AVCaptureSession.Preset.high
        }
        session.commitConfiguration()
    }

    func startCamera() {
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
    
    func stopCamera() {
        if session.isRunning {
            sessionQueue.async { [unowned self] in
                self.session.stopRunning()
            }
        }
    }
    
    @objc
    func shotButtonTapped() {
        isRecording = !isRecording
        
        let shotImage: UIImage?
        if isRecording {
            shotImage = videoStopImage
        } else {
            shotImage = videoStartImage
        }
        v.shotButton.setImage(shotImage, for: .normal)
        
        if isRecording {
            let outputPath = "\(NSTemporaryDirectory())output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputPath) {
                do {
                    try fileManager.removeItem(atPath: outputPath)
                } catch {
                    isRecording = false
                    return
                }
            }
            v.flipButton.isEnabled = false
            v.flashButton.isEnabled = false
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        } else {
            videoOutput.stopRecording()
            v.flipButton.isEnabled = true
            v.flashButton.isEnabled = true
        }
        return
    }
    
    @objc
    func flipButtonTapped() {
        sessionQueue.async { [unowned self] in
            self.session.beginConfiguration()
            self.session.resetInputs()
            self.videoInput = flippedDeviceInputForInput(self.videoInput)
            if self.session.canAddInput(self.videoInput) {
                self.session.addInput(self.videoInput)
            }
            
            // Re Add audio recording
            for device in AVCaptureDevice.devices(for:AVMediaType.audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: device) {
                    if self.session.canAddInput(audioInput) {
                        self.session.addInput(audioInput)
                    }
                }
            }
            self.session.commitConfiguration()
            DispatchQueue.main.async {
                self.refreshFlashButton()
            }
        }
    }
    
    @objc
    func flashButtonTapped() {
        device?.tryToggleFlash()
        refreshFlashButton()
    }
    
    func flashImage(forAVCaptureFlashMode: AVCaptureDevice.FlashMode) -> UIImage {
        switch forAVCaptureFlashMode {
        case .on: return flashOnImage!
        case .off: return flashOffImage!
        default: return flashOffImage!
        }
    }
}

extension FSVideoVC: AVCaptureFileOutputRecordingDelegate {
    
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
    
    @objc
    func tick() {
        let timeElapsed = Date().timeIntervalSince(dateVideoStarted)
        v.timeElapsedLabel.text = formattedStrigFrom(timeElapsed)
        let p: Float = Float(timeElapsed) / Float(30)
        DispatchQueue.main.async {
            self.v.progressBar.progress = p
            UIView.animate(withDuration: 1, animations: {
                self.v.layoutIfNeeded()
            })
        }
    }
    
    func foo(_ timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let r = timeInterval-Double(interval)
        let miliseconds: Int = Int(r*100)
        return String(format: "%02d:%02d", seconds, miliseconds)
    }
    
    public func fileOutput(_ captureOutput: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        didCaptureVideo?(outputFileURL)
        resetVisualState()
        timer.invalidate()
    }
    
    private func resetVisualState() {
        v.progressBar.progress = 0
        v.timeElapsedLabel.text = "00:00"
    }
}

extension FSVideoVC {
    
    @objc
    func focus(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: v.previewViewContainer)
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x:point.x/viewsize.width, y:point.y/viewsize.height)
        setFocusPointOnDevice(device: device!, point: newPoint)
        focusView.center = point
        configureFocusView(focusView)
        v.addSubview(focusView)
        animateFocusView(focusView)
    }
    
    func refreshFlashButton() {
        if let device = device {
            v.flashButton.setImage(flashImage(forAVCaptureFlashMode:device.flashMode), for: .normal)
        }
    }
}
