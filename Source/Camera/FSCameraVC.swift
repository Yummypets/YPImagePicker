//
//  FSCameraVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

public class FSCameraVC: UIViewController, UIGestureRecognizerDelegate {
    
    public var usesFrontCamera = false
    public var didCapturePhoto: ((UIImage) -> Void)?
    private let sessionQueue = DispatchQueue(label: "FSCameraVCSerialQueue")
    let session = AVCaptureSession()
    var device: AVCaptureDevice? {
        return videoInput?.device
    }
    var videoInput: AVCaptureDeviceInput!
    let imageOutput = AVCaptureStillImageOutput()
    let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
    var v = FSCameraView()
    var isPreviewSetup = false
    
    override public func loadView() { view = v }
    
    convenience init(shouldUseFrontCamera: Bool) {
        self.init(nibName:nil, bundle:nil)
        usesFrontCamera = shouldUseFrontCamera
        title = fsLocalized("YPImagePickerPhoto")
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
        tapRecognizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
    }
    
    private func setupCaptureSession() {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.photo
        let cameraPosition: AVCaptureDevice.Position = usesFrontCamera ? .front : .back
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
    
    func startCamera() {
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
    func flipButtonTapped() {
        sessionQueue.async { [unowned self] in
            self.session.resetInputs()
            self.videoInput = flippedDeviceInputForInput(self.videoInput)
            if self.session.canAddInput(self.videoInput) {
                self.session.addInput(self.videoInput)
            }
            DispatchQueue.main.async {
                self.refreshFlashButton()
            }
        }
    }

    @objc
    func shotButtonTapped() {
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
                if let image = UIImage(data: data!) {
                    
                    // Image size
                    var iw: CGFloat
                    var ih: CGFloat
                    
                    switch orientation {
                    case .landscapeLeft, .landscapeRight:
                        // Swap width and height if orientation is landscape
                        iw = image.size.height
                        ih = image.size.width
                    default:
                        iw = image.size.width
                        ih = image.size.height
                    }
                    // Frame size
                    let sw = self.v.previewViewContainer.frame.width
                    // The center coordinate along Y axis
                    let rcy = ih * 0.5
                    let imageRef = image.cgImage?.cropping(to: CGRect(x: rcy-iw*0.5, y: 0, width: iw, height: iw))
                    DispatchQueue.main.async {
                        var resizedImage = UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
                        if let device = self.device, let cgImg =  resizedImage.cgImage, device.position == .front {
                            func flipImage(image: UIImage!) -> UIImage! {
                                let imageSize: CGSize = image.size
                                UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
                                let ctx = UIGraphicsGetCurrentContext()!
                                ctx.rotate(by: CGFloat(Double.pi/2.0))
                                ctx.translateBy(x: 0, y: -imageSize.width)
                                ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
                                ctx.draw(image.cgImage!, in: CGRect(x:0.0,
                                                                    y:0.0,
                                                                    width:imageSize.width,
                                                                    height:imageSize.height))
                                let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                                UIGraphicsEndImageContext()
                                return newImage
                            }
                            resizedImage = flipImage(image: resizedImage)
                        }
                        self.didCapturePhoto?(resizedImage)
                    }
                }
            }
        }
    }
    
    @objc
    func flashButtonTapped() {
        device?.tryToggleFlash()
        refreshFlashButton()
    }
    
    func refreshFlashButton() {
        if let device = device {
            v.flashButton.setImage(flashImage(forAVCaptureFlashMode:device.flashMode), for: .normal)
            v.flashButton.isHidden = !device.hasFlash
        }
    }

    func flashImage(forAVCaptureFlashMode: AVCaptureDevice.FlashMode) -> UIImage {
        switch forAVCaptureFlashMode {
        case .on: return flashOnImage!
        case .off: return flashOffImage!
        default: return flashOffImage!
        }
    }
}
