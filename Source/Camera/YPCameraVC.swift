//
//  YPCameraVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public class YPCameraVC: UIViewController, UIGestureRecognizerDelegate, PermissionCheckable {
    
    public var didCapturePhoto: ((UIImage) -> Void)?
    private let sessionQueue = DispatchQueue(label: "YPCameraVCSerialQueue", qos: .background)
    let session = AVCaptureSession()
    var device: AVCaptureDevice? {
        return videoInput?.device
    }
    var videoInput: AVCaptureDeviceInput!
    let imageOutput = AVCaptureStillImageOutput()
    var v = YPCameraView()
    var isPreviewSetup = false
    
    override public func loadView() { view = v }
    
    private let configuration: YPImagePickerConfiguration!
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        title = ypLocalized("YPImagePickerPhoto")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        v.flashButton.isHidden = true
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        sessionQueue.async { [unowned self] in
            self.setupCaptureSession()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isPreviewSetup {
            startCamera()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshFlashButton()
    }
    
    func tryToSetupPreview() {
        if !isPreviewSetup {
            setupPreview()
            isPreviewSetup = true
        }
    }
    
    func setupPreview() {
        let videoLayer = AVCaptureVideoPreviewLayer(session: session)
        
        DispatchQueue.main.async {
            videoLayer.frame = self.v.previewViewContainer.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.v.previewViewContainer.layer.addSublayer(videoLayer)
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusTapped(_:)))
            tapRecognizer.delegate = self
            self.v.previewViewContainer.addGestureRecognizer(tapRecognizer)
        }
    }
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.photo
        let cameraPosition: AVCaptureDevice.Position = self.configuration.usesFrontCamera ? .front : .back
        let aDevice = deviceForPosition(cameraPosition)
        if let d = aDevice {
            videoInput = try? AVCaptureDeviceInput(device: d)
        }
        if let videoInput = videoInput {
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            if session.canAddOutput(imageOutput) {
                session.addOutput(imageOutput)
            }
        }
        session.commitConfiguration()
    }
    
    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        doAfterPermissionCheck { [weak self] in
            self?.focus(recognizer: recognizer)
        }
    }
    
    func focus(recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: v.previewViewContainer)
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        setFocusPointOnDevice(device: device!, point: newPoint)
        v.focusView.center = point
        configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        animateFocusView(v.focusView)
    }
    
    public func tryToStartCamera() {
        doAfterPermissionCheck { [weak self] in
            self?.startCamera()
        }
    }
    
    private func startCamera() {
        if !session.isRunning {
            sessionQueue.async { [unowned self] in
                // Re-apply session preset
                self.session.sessionPreset = AVCaptureSession.Preset.photo
                let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
                switch status {
                case .notDetermined, .restricted, .denied:
                    self.session.stopRunning()
                case .authorized:
                    self.session.startRunning()
                    self.tryToSetupPreview()
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
    
    @objc
    func flipButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.flip()
        }
    }
    
    func flip() {
        sessionQueue.async { [weak self] in
            self?.flipCamera()
        }
    }
    
    private func flipCamera() {
        session.resetInputs()
        videoInput = flippedDeviceInputForInput(videoInput)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        DispatchQueue.main.async {
            self.refreshFlashButton()
        }
    }

    @objc
    func shotButtonTapped() {
        doAfterPermissionCheck { [weak self] in
            self?.shoot()
        }
    }
    
    func shoot() {
        // Prevent from tapping multiple times in a row
        // causing a crash
        v.shotButton.isEnabled = false
        
        DispatchQueue.global(qos: .default).async {
            let videoConnection = self.imageOutput.connection(with: AVMediaType.video)
            let orientation: UIDeviceOrientation = UIDevice.current.orientation
            switch orientation {
            case .portrait:
                videoConnection?.videoOrientation = .portrait
            case .portraitUpsideDown:
                videoConnection?.videoOrientation = .portraitUpsideDown
            case .landscapeRight:
                videoConnection?.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                videoConnection?.videoOrientation = .landscapeRight
            default:
                videoConnection?.videoOrientation = .portrait
            }
            
            self.imageOutput.captureStillImageAsynchronously(from: videoConnection!) { buffer, _ in
                self.session.stopRunning()
                let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer!)
                if var image = UIImage(data: data!) {
                    
                    // Crop the image if the output needs to be square.
                    if self.configuration.onlySquareImagesFromCamera {
                        image = self.cropImageToSquare(image)
                    }
                    
                    // Flip image if taken form the front camera.
                    if let device = self.device, device.position == .front {
                        image = self.flipImage(image: image)
                    }
                    
                    DispatchQueue.main.async {
                        let noOrietationImage = image.resetOrientation()
                        self.didCapturePhoto?(noOrietationImage)
                    }
                }
            }
        }
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        var imageWidth = image.size.width
        var imageHeight = image.size.height
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            // Swap width and height if orientation is landscape
            imageWidth = image.size.height
            imageHeight = image.size.width
        default:
            break
        }
        
        // The center coordinate along Y axis
        let rcy = imageHeight * 0.5
        let rect = CGRect(x: rcy - imageWidth * 0.5, y: 0, width: imageWidth, height: imageWidth)
        let imageRef = image.cgImage?.cropping(to: rect)
        return UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
    }
    
    // Used when image is taken from the front camera.
    func flipImage(image: UIImage!) -> UIImage! {
        let imageSize: CGSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.rotate(by: CGFloat(Double.pi/2.0))
        ctx.translateBy(x: 0, y: -imageSize.width)
        ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
        ctx.draw(image.cgImage!, in: CGRect(x: 0.0,
                                            y: 0.0,
                                            width: imageSize.width,
                                            height: imageSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @objc
    func flashButtonTapped() {
        device?.tryToggleFlash()
        refreshFlashButton()
    }
    
    func refreshFlashButton() {
        if let device = device {
            v.flashButton.setImage(flashImage(forAVCaptureFlashMode: device.flashMode), for: .normal)
            v.flashButton.isHidden = !device.hasFlash
        }
    }

    func flashImage(forAVCaptureFlashMode: AVCaptureDevice.FlashMode) -> UIImage {
        switch forAVCaptureFlashMode {
        case .on: return flashOnImage!
        case .off: return flashOffImage!
        case .auto: return flashAutoImage!
        }
    }
}

class YPPermissionDeniedPopup {
    
    static func popup(cancelBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title: ypLocalized("YPImagePickerPermissionDeniedPopupTitle"),
                                      message: ypLocalized("YPImagePickerPermissionDeniedPopupMessage"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: ypLocalized("YPImagePickerPermissionDeniedPopupCancel"),
                                      style: UIAlertActionStyle.cancel,
                                      handler: { _ in
                                        cancelBlock()
        }))
        alert.addAction(UIAlertAction(title: ypLocalized("YPImagePickerPermissionDeniedPopupGrantPermission"),
                                      style: .default,
                                      handler: { _ in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
            } else {
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }
        }))
        return alert
    }
}

