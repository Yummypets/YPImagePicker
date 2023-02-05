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

internal final class YPCameraVC: UIViewController, UIGestureRecognizerDelegate, YPPermissionCheckable {
    var didCapturePhoto: ((UIImage) -> Void)?
    let v: YPCameraView!

    private let photoCapture = YPPhotoCaptureHelper()
    private var isInited = false
    private var videoZoomFactor: CGFloat = 1.0

    override internal func loadView() {
        view = v
    }

    internal required init() {
        self.v = YPCameraView(overlayView: YPConfig.overlayView)
        super.init(nibName: nil, bundle: nil)

        title = YPConfig.wordings.cameraTitle
        navigationController?.navigationBar.setTitleFont(font: YPConfig.fonts.navigationBarTitleFont)
        
        YPDeviceOrientationHelper.shared.startDeviceOrientationNotifier { _ in }
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        YPDeviceOrientationHelper.shared.stopDeviceOrientationNotifier()
    }
    
    override internal func viewDidLoad() {
        super.viewDidLoad()

        v.flashButton.isHidden = true
        v.flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        v.shotButton.addTarget(self, action: #selector(shotButtonTapped), for: .touchUpInside)
        v.flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        
        // Prevent flip and shot button clicked at the same time
        v.shotButton.isExclusiveTouch = true
        v.flipButton.isExclusiveTouch = true
        
        // Focus
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.focusTapped(_:)))
        tapRecognizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(tapRecognizer)
        
        // Zoom
        let pinchRecongizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(_:)))
        pinchRecongizer.delegate = self
        v.previewViewContainer.addGestureRecognizer(pinchRecongizer)
    }
    
    func start() {
        doAfterCameraPermissionCheck { [weak self] in
            guard let previewContainer = self?.v.previewViewContainer else {
                return
            }

            self?.photoCapture.start(with: previewContainer, completion: {
                DispatchQueue.main.async {
                    self?.isInited = true
                    self?.updateFlashButtonUI()
                }
            })
        }
    }

    @objc
    func focusTapped(_ recognizer: UITapGestureRecognizer) {
        guard isInited else {
            return
        }
        
        self.focus(recognizer: recognizer)
    }
    
    func focus(recognizer: UITapGestureRecognizer) {

        let point = recognizer.location(in: v.previewViewContainer)
        
        // Focus the capture
        let viewsize = v.previewViewContainer.bounds.size
        let newPoint = CGPoint(x: point.x/viewsize.width, y: point.y/viewsize.height)
        photoCapture.focus(on: newPoint)
        
        // Animate focus view
        v.focusView.center = point
        YPHelper.configureFocusView(v.focusView)
        v.addSubview(v.focusView)
        YPHelper.animateFocusView(v.focusView)
    }
    
    @objc
    func pinch(_ recognizer: UIPinchGestureRecognizer) {
        guard isInited else {
            return
        }
        
        self.zoom(recognizer: recognizer)
    }
    
    func zoom(recognizer: UIPinchGestureRecognizer) {
        photoCapture.zoom(began: recognizer.state == .began, scale: recognizer.scale)
    }

    func stopCamera() {
        photoCapture.stopCamera()
    }
    
    @objc
    func flipButtonTapped() {
        self.photoCapture.flipCamera {
            self.updateFlashButtonUI()
        }
    }
    
    @objc
    func shotButtonTapped() {
        doAfterCameraPermissionCheck { [weak self] in
            self?.shoot()
        }
    }
    
    func shoot() {
        // Prevent from tapping multiple times in a row
        // causing a crash
        v.shotButton.isEnabled = false

        photoCapture.shoot { imageData in
            
            guard let shotImage = UIImage(data: imageData) else {
                return
            }
            
            self.photoCapture.stopCamera()
            
            var image = shotImage
            // Crop the image if the output needs to be square.
            if YPConfig.onlySquareImagesFromCamera {
                image = self.cropImageToSquare(image)
            }

            // Flip image if taken form the front camera.
            if let device = self.photoCapture.device, device.position == .front {
                image = self.flipImage(image: image)
            }
            
            let noOrietationImage = image.resetOrientation()
            
            DispatchQueue.main.async {
                self.didCapturePhoto?(noOrietationImage.resizedImageIfNeeded())
            }
        }
    }
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
        let orientation: UIDeviceOrientation = YPDeviceOrientationHelper.shared.currentDeviceOrientation
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
        photoCapture.device?.tryToggleTorch()
        updateFlashButtonUI()
    }
    
    func updateFlashButtonUI() {
        DispatchQueue.main.async {
            let flashImage = self.photoCapture.currentFlashMode.flashImage()
            self.v.flashButton.setImage(flashImage, for: .normal)
            self.v.flashButton.isHidden = !self.photoCapture.hasFlash
        }
    }
}
