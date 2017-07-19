//
//  FusumaVC.swift
//  Fusuma
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 ytakzk. All rights reserved.
//

import Foundation
import Stevia

var flashOffImage: UIImage?
var flashOnImage: UIImage?
var videoStartImage: UIImage?
var videoStopImage: UIImage?

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}

public class FusumaVC: FSBottomPager, PagerDelegate {
    
    var shouldShowStatusBar = false
    
    override public var prefersStatusBarHidden: Bool { return shouldShowStatusBar }
    
    public var showsVideo = false
    public var usesFrontCamera = false
    
    public var didClose:(() -> Void)?
    public var didSelectImage: ((UIImage, Bool) -> Void)?
    public var didSelectVideo: ((URL) -> Void)?
    
    enum Mode {
        case library
        case camera
        case video
    }
    
    let albumVC = FSAlbumVC()
    lazy var cameraVC: FSCameraVC = {
        return FSCameraVC(shouldUseFrontCamera: self.usesFrontCamera)
    }()
    let videoVC = FSVideoVC()
    
    var mode = Mode.camera
    
    var capturedImage: UIImage?
    
    func imageFromBundle(_ named: String) -> UIImage {
        let bundle = Bundle(for: self.classForCoder)
        return UIImage(named: named, in: bundle, compatibleWith: nil) ?? UIImage()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        flashOnImage = imageFromBundle("yp_iconFlash_on")
        flashOffImage = imageFromBundle("yp_iconFlash_off")
        
        albumVC.showsVideo = showsVideo
        albumVC.delegate = self
        
        view.backgroundColor = UIColor(r:247, g:247, b:247)
        cameraVC.didCapturePhoto = { [unowned self] img in
            self.didSelectImage?(img, true)
        }
        videoVC.didCaptureVideo = { [unowned self] videoURL in
            self.didSelectVideo?(videoURL)
        }
        delegate = self
        
        if controllers.isEmpty {
            if showsVideo {
                controllers = [albumVC, cameraVC, videoVC]
            } else {
                controllers = [albumVC, cameraVC]
            }
        }
        
        startOnPage(1)
        
        updateUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCurrentCamera()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldShowStatusBar = true
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) {    }
    
    func pagerDidSelectController(_ vc: UIViewController) {
        
        var changedMode = true
        
        switch mode {
        case .library where vc == albumVC:
            changedMode = false
        case .camera where vc == cameraVC:
            changedMode = false
        case .video where vc == videoVC:
            changedMode = false
        default:()
        }
        
        if changedMode {
            
            // Set new mode
            if vc == albumVC {
                mode = .library
            } else if vc == cameraVC {
                mode = .camera
            } else if vc == videoVC {
                mode = .video
            }
            
            updateUI()
            stopCamerasNotShownOnScreen()
            startCurrentCamera()
        }
    }
    
    func stopCamerasNotShownOnScreen() {
        if mode != .video {
            videoVC.stopCamera()
        }
        if mode != .camera {
            cameraVC.stopCamera()
        }
    }
    
    func startCurrentCamera() {
        //Start current camera
        switch mode {
        case .library:
            break
        case .camera:
            self.cameraVC.startCamera()
        case .video:
            self.videoVC.startCamera()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldShowStatusBar = false
        stopAll()
    }
    
    func updateUI() {
        // Update Nav Bar state.
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(close))
        navigationItem.leftBarButtonItem?.tintColor = UIColor(r: 38, g: 38, b: 38)
        switch mode {
        case .library:
            title = albumVC.title
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: fsLocalized("YPFusumaNext"),
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .camera:
            title = cameraVC.title
            navigationItem.rightBarButtonItem = nil
        case .video:
            title = videoVC.title
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func close() {
        dismiss(animated: true) {
            self.didClose?()
        }
    }
    
    func done() {
        if mode == .library {
            albumVC.selectedMedia(photo: { img in
                self.didSelectImage?(img, false)
            }, video: { videoURL in
                self.didSelectVideo?(videoURL)
            })
        }
    }
    
    func stopAll() {
        videoVC.stopCamera()
        cameraVC.stopCamera()
    }
}

extension FusumaVC: FSAlbumViewDelegate {
    
    public func albumViewStartedLoadingImage() {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:spinner)
            spinner.startAnimating()
        }
    }
    
    public func albumViewFinishedLoadingImage() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: fsLocalized("YPFusumaNext"),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
    }
    
    public func albumViewCameraRollUnauthorized() {
        
    }
}
