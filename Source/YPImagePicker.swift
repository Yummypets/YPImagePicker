//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

public class YPImagePicker: UINavigationController {
    
    /// Set a global configuration that will be applied whenever you call YPImagePicker().
    public static func setDefaultConfiguration(_ config: YPImagePickerConfiguration) {
        defaultConfiguration = config
    }
    
    private static var defaultConfiguration = YPImagePickerConfiguration()
    
    private let configuration: YPImagePickerConfiguration!
    private let picker: YPPickerVC!
    
    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        let defaultConf = YPImagePicker.defaultConfiguration
        self.init(configuration: defaultConf)
    }
    
    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        picker = YPPickerVC(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var didSelectImage: ((UIImage) -> Void)?
    public var didSelectVideo: ((Data, UIImage, URL) -> Void)?
    
    private let loadingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        return view
    }()
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.hidesWhenStopped = true
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    private let label: UILabel = {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 20)
        let label = UILabel(frame: frame)
        label.text = NSLocalizedString("Processing...", comment: "Processing...")
        label.textColor = .white
        return label
    }()
    
    private func setupActivityIndicator() {
        self.view.addSubview(loadingContainerView)
        loadingContainerView.alpha = 0
        loadingContainerView.frame = self.view.bounds
        
        loadingContainerView.addSubview(label)
        let labelWidth: CGFloat = 200.0
        let labelHeight: CGFloat = 20.0
        let offset: CGFloat = 40.0
        let frame = CGRect(x: (loadingContainerView.frame.width/2) - offset,
                           y: (loadingContainerView.frame.height/2) + offset,
                           width: labelWidth,
                           height: labelHeight)
        label.frame = frame
        
        loadingContainerView.addSubview(activityIndicatorView)
        activityIndicatorView.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor).isActive = true
    }
    
    func showHideActivityIndicator() {
        
        if !activityIndicatorView.isAnimating {
            activityIndicatorView.startAnimating()
            loadingContainerView.alpha = 1
        } else {
            activityIndicatorView.stopAnimating()
            loadingContainerView.alpha = 0
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [picker]
        setupActivityIndicator()
        navigationBar.isTranslucent = false
        picker.didSelectImage = { [unowned self] pickedImage, isNewPhoto in
            if self.configuration.showsFilters {
                let filterVC = YPFiltersVC(image: pickedImage)
                filterVC.didSelectImage = { filteredImage, isImageFiltered in
                    
                    let completion = { (image: UIImage) in
                        self.didSelectImage?(image)
                        if (isNewPhoto || isImageFiltered) && self.configuration.shouldSaveNewPicturesToAlbum {
                            YPPhotoSaver.trySaveImage(filteredImage, inAlbumNamed: self.configuration.albumName)
                        }
                    }
                    
                    if case let YPCropType.rectangle(ratio) = self.configuration.showsCrop {
                        let cropVC = YPCropVC(image: filteredImage, ratio: ratio)
                        cropVC.didFinishCropping = { croppedImage in
                            completion(croppedImage)
                        }
                        self.pushViewController(cropVC, animated: true)
                    } else {
                        completion(filteredImage)
                    }
                }
                
                // Use Fade transition instead of default push animation
                let transition = CATransition()
                transition.duration = 0.3
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                transition.type = kCATransitionFade
                self.view.layer.add(transition, forKey: nil)
                
                self.pushViewController(filterVC, animated: false)
            } else {
                let completion = { (image: UIImage) in
                    self.didSelectImage?(image)
                    if isNewPhoto && self.configuration.shouldSaveNewPicturesToAlbum {
                        YPPhotoSaver.trySaveImage(pickedImage, inAlbumNamed: self.configuration.albumName)
                    }
                }
                if case let YPCropType.rectangle(ratio) = self.configuration.showsCrop {
                    let cropVC = YPCropVC(image: pickedImage, ratio: ratio)
                    cropVC.didFinishCropping = { croppedImage in
                        completion(croppedImage)
                    }
                    self.pushViewController(cropVC, animated: true)
                } else {
                    completion(pickedImage)
                }
            }
        }
        
        picker.didSelectVideo = { [unowned self] videoURL in
            
            self.showHideActivityIndicator()
            
            DispatchQueue.global(qos: .background).async {
                let thumb = thunbmailFromVideoPath(videoURL)
                // Compress Video to 640x480 format.
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                if let firstPath = paths.first {
                    
                    let path = firstPath + "/\(Int(Date().timeIntervalSince1970))temporary.mov"
                    let uploadURL = URL(fileURLWithPath: path)
                    let asset = AVURLAsset(url: videoURL)
                    
                    let exportSession = AVAssetExportSession(asset: asset,
                                                             presetName: self.configuration.videoCompression)
                    exportSession?.outputURL = uploadURL
                    exportSession?.outputFileType = AVFileType.mov
                    exportSession?.shouldOptimizeForNetworkUse = true //USEFUL?
                    exportSession?.exportAsynchronously {
                        switch exportSession!.status {
                        case .completed:
                            if let videoData = FileManager.default.contents(atPath: uploadURL.path) {
                                DispatchQueue.main.async {
                                    self.showHideActivityIndicator()
                                    self.didSelectVideo?(videoData, thumb, uploadURL)
                                }
                            }
                        default:
                            // Fall back to default video size:
                            if let videoData = FileManager.default.contents(atPath: videoURL.path) {
                                DispatchQueue.main.async {
                                    self.showHideActivityIndicator()
                                    self.didSelectVideo?(videoData, thumb, uploadURL)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

func thunbmailFromVideoPath(_ path: URL) -> UIImage {
    let asset = AVURLAsset(url: path, options: nil)
    let gen = AVAssetImageGenerator(asset: asset)
    gen.appliesPreferredTrackTransform = true
    let time = CMTimeMakeWithSeconds(0.0, 600)
    var actualTime = CMTimeMake(0, 0)
    let image: CGImage
    do {
        image = try gen.copyCGImage(at: time, actualTime: &actualTime)
        let thumbnail = UIImage(cgImage: image)
        return thumbnail
    } catch { }
    return UIImage()
}
