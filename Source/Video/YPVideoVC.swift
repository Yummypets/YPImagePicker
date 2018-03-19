//
//  YPVideoVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit

public class YPVideoVC: UIViewController, PermissionCheckable {
    
    public var didCaptureVideo: ((URL) -> Void)?
    
    private let videoHelper = YPVideoHelper()
    private let v = YPCameraView(overlayView: nil)
    private var isPreviewSetup = false
    let configuration: YPImagePickerConfiguration!
    private var viewState = ViewState()
    
    // MARK: - Init
    
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = configuration.wordings.videoTitle
        
        videoHelper.initialize(withVideoRecordingLimit: configuration.videoRecordingTimeLimit)
        
        videoHelper.didCaptureVideo = { [weak self] videoURL in
            self?.didCaptureVideo?(videoURL)
            self?.resetVisualState()
        }
        
        videoHelper.videoRecordingProgress = { [weak self] progress, timeElapsed in
            self?.updateState {
                $0.progress = progress
                $0.timeElapsed = timeElapsed
            }
        }
    }
    
    // MARK: - View LifeCycle
    
    override public func loadView() { view = v }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        v.timeElapsedLabel.isHidden = false // Show the time elapsed label since we're in the video screen.
        setupButtons()
        linkButtons()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
        
        // Init view state with video helper's state
        updateState {
            $0.isRecording = self.videoHelper.isRecording
            $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
        }
    }
    
    // MARK: - Setup
    
    private func setupButtons() {
        videoStartImage = imageFromBundle("yp_iconVideoCapture")
        videoStopImage = imageFromBundle("yp_iconVideoCaptureRecording")
        v.flashButton.setImage(flashOffImage, for: .normal)
        v.flipButton.setImage(imageFromBundle("yp_iconLoop"), for: .normal)
        v.shotButton.setImage(videoStartImage, for: .normal)
    }
    
    private func linkButtons() {
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
    }
    
    private func setupPreview() {
        let videoLayer = videoHelper.newVideoLayer()
        videoLayer.frame = v.previewViewContainer.bounds
        v.previewViewContainer.layer.addSublayer(videoLayer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(focusTapped(_:)))
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: - Flip Camera
    
    @objc
    func flipButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.flip()
        }
    }
    
    private func flip() {
        videoHelper.flipCamera {
            self.updateState {
                $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
            }
        }
    }
    
    // MARK: - Toggle Flash
    
    @objc
    func flashButtonTapped() {
        videoHelper.toggleTorch()
        updateState {
            $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
        }
    }
    
    // MARK: - Toggle Recording
    
    @objc
    func shotButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.toggleRecording()
        }
    }
    
    private func toggleRecording() {
        videoHelper.isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        videoHelper.startRecording()
        updateState {
            $0.isRecording = true
        }
    }
    
    private func stopRecording() {
        videoHelper.stopRecording()
        updateState {
            $0.isRecording = false
        }
    }
    
    public func tryToStartCamera() {
        doAfterPermissionCheck { [weak self] in
            self?.videoHelper.startCamera()
        }
    }
    
    public func stopCamera() {
        videoHelper.stopCamera()
    }
    
    // MARK: - Focus
    
    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        doAfterPermissionCheck { [weak self] in
            self?.focus(recognizer: recognizer)
        }
    }
    
    private func focus(recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: v.previewViewContainer)
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        videoHelper.focus(onPoint: newPoint)
        v.focusView.center = point
        configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        animateFocusView(v.focusView)
    }
    
    // MARK: - UI State
    
    enum FlashMode {
        case noFlash
        case off
        case on
        case auto
    }
    
    struct ViewState {
        var isRecording = false
        var flashMode = FlashMode.noFlash
        var progress: Float = 0
        var timeElapsed: TimeInterval = 0
    }
    
    private func updateState(block:(inout ViewState) -> Void) {
        block(&viewState)
        updateUIWith(state: viewState)
    }
    
    private func updateUIWith(state: ViewState) {
        func flashImage(for torchMode: FlashMode) -> UIImage {
            switch torchMode {
            case .noFlash: return UIImage()
            case .on: return flashOnImage!
            case .off: return flashOffImage!
            case .auto: return flashAutoImage!
            }
        }
        v.flashButton.setImage(flashImage(for: state.flashMode), for: .normal)
        v.flashButton.isEnabled = !state.isRecording
        v.flashButton.isHidden = state.flashMode == .noFlash
        v.shotButton.setImage(state.isRecording ? videoStopImage : videoStartImage, for: .normal)
        v.flipButton.isEnabled = !state.isRecording
        v.progressBar.progress = state.progress
        v.timeElapsedLabel.text = formattedStrigFrom(state.timeElapsed)
        UIView.animate(withDuration: 1, animations: v.layoutIfNeeded)
    }
    
    private func resetVisualState() {
        updateState {
            $0.isRecording = self.videoHelper.isRecording
            $0.flashMode = self.flashModeFrom(videoHelper: self.videoHelper)
            $0.progress = 0
            $0.timeElapsed = 0
        }
    }
    
    private func flashModeFrom(videoHelper: YPVideoHelper) -> FlashMode {
        if videoHelper.hasTorch() {
            switch videoHelper.currentTorchMode() {
            case .off: return .off
            case .on: return .on
            case .auto: return .auto
            }
        } else {
            return .noFlash
        }
    }
}
