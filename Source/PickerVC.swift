//
//  YPImgePickerVC.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
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

public class PickerVC: FSBottomPager, PagerDelegate {
    
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    
    override public var prefersStatusBarHidden: Bool {
        return shouldHideStatusBar || initialStatusBarHidden
    }
    
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
        shouldHideStatusBar = true
        initialStatusBarHidden = true
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
        shouldHideStatusBar = false
        stopAll()
    }
    
    @objc
    func navBarTapped() {
        
        let vc = YPAlbumFolderSelectionVC()
        vc.noVideos = !showsVideo
        let navVC = UINavigationController(rootViewController: vc)

        vc.didSelectAlbum = { [weak self] album in
            self?.albumVC.collection = album.collection
            self?.albumVC.refreshMediaRequest()
            self?.setTitleViewWithTitle(aTitle: album.title)
            self?.dismiss(animated: true, completion: nil)
        }
        present(navVC, animated: true, completion: nil)
    }
    
    func setTitleViewWithTitle(aTitle: String) {
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        
        let label = UILabel()
        label.text = aTitle
        label.textColor = .black
        
        let arrow = UIImageView()
        arrow.image = imageFromBundle("yp_arrow")
        
        let button = UIButton()
        button.addTarget(self, action: #selector(navBarTapped), for: .touchUpInside)
        button.setBackgroundColor(UIColor.white.withAlphaComponent(0.5), forState: .highlighted)
        
        titleView.sv(
            label,
            arrow,
            button
        )
        
        |-(>=8)-label.centerInContainer()-(>=8)-|
    
        button.fillContainer()
        alignHorizontally(label-arrow)
        
        navigationItem.titleView = titleView
    }
    
    func updateUI() {
        // Update Nav Bar state.
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(close))
        navigationItem.leftBarButtonItem?.tintColor = UIColor(r: 38, g: 38, b: 38)
        switch mode {
        case .library:
//            title = albumVC.title
            setTitleViewWithTitle(aTitle: albumVC.title ?? "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: fsLocalized("YPImagePickerNext"),
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .camera:
            navigationItem.titleView = nil
            title = cameraVC.title
            navigationItem.rightBarButtonItem = nil
        case .video:
            navigationItem.titleView = nil
            title = videoVC.title
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc
    func close() {
        dismiss(animated: true) {
            self.didClose?()
        }
    }
    
    @objc
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

extension PickerVC: FSAlbumViewDelegate {
    
    public func albumViewStartedLoadingImage() {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:spinner)
            spinner.startAnimating()
        }
    }
    
    public func albumViewFinishedLoadingImage() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: fsLocalized("YPImagePickerNext"),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
    }
    
    public func albumViewCameraRollUnauthorized() {
        
    }
}

public extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState: UIControlState) {
        setBackgroundImage(imageWithColor(color), for: forState)
    }
}

func imageWithColor(_ color: UIColor) -> UIImage {
    let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image ?? UIImage()
}
