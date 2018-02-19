//
//  YYPPickerVC.swift
//  YPPickerVC
//
//  Created by Sacha Durand Saint Omer on 25/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import Stevia

var flashOffImage: UIImage?
var flashOnImage: UIImage?
var flashAutoImage: UIImage?
var videoStartImage: UIImage?
var videoStopImage: UIImage?

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}

public class YPPickerVC: YPBottomPager, YPBottomPagerDelegate {
    
    private let configuration: YPImagePickerConfiguration!
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var shouldHideStatusBar = false
    var initialStatusBarHidden = false
    
    override public var prefersStatusBarHidden: Bool {
        return shouldHideStatusBar || initialStatusBarHidden
    }
    
    public var didClose:(() -> Void)?
    public var didSelectImage: ((UIImage, Bool) -> Void)?
    public var didSelectVideo: ((URL) -> Void)?
    
    enum Mode {
        case library
        case camera
        case video
    }

    private var libraryVC: YPLibraryVC?
    private var cameraVC: YPCameraVC?
    private var videoVC: YPVideoVC?
    
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
        flashAutoImage = imageFromBundle("yp_iconFlash_auto")
        
        view.backgroundColor = UIColor(r: 247, g: 247, b: 247)

        delegate = self
        
        // Library
        if configuration.screens.contains(.library) {
            libraryVC = YPLibraryVC(configuration: configuration)
            libraryVC?.delegate = self
        }
        
        // Camera
        if configuration.screens.contains(.photo) {
            cameraVC = YPCameraVC(configuration: configuration)
            cameraVC?.didCapturePhoto = { [unowned self] img in
                self.didSelectImage?(img, true)
            }
        }
        
        // Video
        if configuration.screens.contains(.video) {
            videoVC = YPVideoVC(configuration: configuration)
            videoVC?.didCaptureVideo = { [unowned self] videoURL in
                self.didSelectVideo?(videoURL)
            }
        }
    
        // Show screens
        var vcs = [UIViewController]()
        for screen in configuration.screens {
            switch screen {
            case .library:
                if let libraryVC = libraryVC {
                    vcs.append(libraryVC)
                }
            case .photo:
                if let cameraVC = cameraVC {
                    vcs.append(cameraVC)
                }
            case .video:
                if let videoVC = videoVC {
                    vcs.append(videoVC)
                }
            }
        }
        controllers = vcs
      
        // Select good mode
        if configuration.screens.contains(configuration.startOnScreen) {
            switch configuration.startOnScreen {
            case .library:
                mode = .library
            case .photo:
                mode = .camera
            case .video:
                mode = .video
            }
        }
        
        // Select good screen
        if let index = configuration.screens.index(of: configuration.startOnScreen) {
            startOnPage(index)
        }
        
        updateMode(with: currentController)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraVC?.v.shotButton.isEnabled = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldHideStatusBar = true
        initialStatusBarHidden = true
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    internal func pagerScrollViewDidScroll(_ scrollView: UIScrollView) { }
    
    func modeFor(vc: UIViewController) -> Mode {
        switch vc {
        case is YPLibraryVC:
            return .library
        case is YPCameraVC:
            return .camera
        case is YPVideoVC:
            return .video
        default:
            return .camera
        }
    }
    
    func pagerDidSelectController(_ vc: UIViewController) {
        updateMode(with: vc)
    }
    
    func updateMode(with vc: UIViewController) {
        stopCurrentCamera()
        
        // Set new mode
        mode = modeFor(vc: vc)
        
        // Re-trigger permission check
        if let vc = vc as? PermissionCheckable {
            vc.checkPermission()
        }
        
        updateUI()
        startCurrentCamera()
    }
    
    func stopCurrentCamera() {
        switch mode {
        case .library:
            libraryVC?.pausePlayer()
        case .camera:
            cameraVC?.stopCamera()
        case .video:
            videoVC?.stopCamera()
        }
    }
    
    func startCurrentCamera() {
        switch mode {
        case .library:
            break
        case .camera:
            cameraVC?.tryToStartCamera()
        case .video:
            videoVC?.tryToStartCamera()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldHideStatusBar = false
        stopAll()
    }
    
    @objc
    func navBarTapped() {
        
        let vc = YPAlbumVC()
        vc.noVideos = !self.configuration.showsVideoInLibrary
        let navVC = UINavigationController(rootViewController: vc)

        vc.didSelectAlbum = { [weak self] album in
            self?.libraryVC?.setAlbum(album)
            self?.libraryVC?.refreshMediaRequest()
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
            setTitleViewWithTitle(aTitle: libraryVC?.title ?? "")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: ypLocalized("YPImagePickerNext"),
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(done))
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .camera:
            navigationItem.titleView = nil
            title = cameraVC?.title
            navigationItem.rightBarButtonItem = nil
        case .video:
            navigationItem.titleView = nil
            title = videoVC?.title
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
            libraryVC?.doAfterPermissionCheck { [weak self] in
                self?.libraryVC?.selectedMedia(photoCallback: { img in
                    self?.didSelectImage?(img, false)
                }, videoCallback: { videoURL in
                    self?.didSelectVideo?(videoURL)
                })
            }
        }
    }
    
    func stopAll() {
        videoVC?.stopCamera()
        cameraVC?.stopCamera()
    }
}

extension YPPickerVC: YPLibraryViewDelegate {
    
    public func libraryViewStartedLoadingImage() {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
            spinner.startAnimating()
        }
    }
    
    public func libraryViewFinishedLoadingImage() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: ypLocalized("YPImagePickerNext"),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(done))
    }
    
    public func libraryViewCameraRollUnauthorized() {
        
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
