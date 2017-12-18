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
    private let picker: PickerVC!
    
    /// Get a YPImagePicker instance with the default configuration.
    public convenience init() {
        let defaultConf = YPImagePicker.defaultConfiguration
        self.init(configuration: defaultConf)
    }
    
    /// Get a YPImagePicker with the specified configuration.
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
        picker = PickerVC(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var didSelectImage: ((UIImage) -> Void)?
    public var didSelectVideo: ((Data, UIImage) -> Void)?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [picker]
        navigationBar.isTranslucent = false
        picker.didSelectImage = { [unowned self] pickedImage, isNewPhoto in
            if self.configuration.showsFilters {
                let filterVC = FiltersVC(image: pickedImage)
                filterVC.didSelectImage = { filteredImage, isImageFiltered in
                    self.didSelectImage?(filteredImage)
                    if (isNewPhoto || isImageFiltered) && self.configuration.shouldSaveNewPicturesToAlbum {
                        PhotoSaver.trySaveImage(filteredImage, inAlbumNamed: self.configuration.albumName)
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
                self.didSelectImage?(pickedImage)
                if isNewPhoto && self.configuration.shouldSaveNewPicturesToAlbum {
                    PhotoSaver.trySaveImage(pickedImage, inAlbumNamed: self.configuration.albumName)
                }
            }
        }
        
        picker.didSelectVideo = { [unowned self] videoURL in
            let thumb = thunbmailFromVideoPath(videoURL)
            // Compress Video to 640x480 format.
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            if let firstPath = paths.first {
                let path = firstPath + "/\(Int(Date().timeIntervalSince1970))temporary.mov"
                let uploadURL = URL(fileURLWithPath: path)
                let asset = AVURLAsset(url: videoURL)
                
                let exportSession = AVAssetExportSession(asset: asset, presetName: self.configuration.videoCompression)
                exportSession?.outputURL = uploadURL
                exportSession?.outputFileType = AVFileType.mov
                exportSession?.shouldOptimizeForNetworkUse = true //USEFUL?
                exportSession?.exportAsynchronously {
                    switch exportSession!.status {
                    case .completed:
                        if let videoData = FileManager.default.contents(atPath: uploadURL.path) {
                            DispatchQueue.main.async {
                                self.didSelectVideo?(videoData, thumb)
                            }
                        }
                    default:
                        // Fall back to default video size:
                        if let videoData = FileManager.default.contents(atPath: videoURL.path) {
                            DispatchQueue.main.async {
                                self.didSelectVideo?(videoData, thumb)
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
