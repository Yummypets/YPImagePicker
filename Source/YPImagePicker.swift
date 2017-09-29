//
//  YPImagePicker.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 27/10/16.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

class YPImagePickerConfiguration {
    static let shared = YPImagePickerConfiguration()
    public var onlySquareImages = false
}

public class YPImagePicker: UINavigationController {
    
    public static var albumName = "DefaultYPImagePickerAlbumName" {
        didSet { PhotoSaver.albumName = albumName }
    }
    
    public var showsVideo = false
    public var usesFrontCamera: Bool {
        get { return picker.usesFrontCamera }
        set { picker.usesFrontCamera = newValue }
    }
    public var showsFilters = true
    public var didSelectImage: ((UIImage) -> Void)?
    public var didSelectVideo: ((Data, UIImage) -> Void)?
    public var onlySquareImages = false {
        didSet {
            YPImagePickerConfiguration.shared.onlySquareImages = onlySquareImages
        }
    }
    
    public var videoCompression: String = AVAssetExportPresetHighestQuality
    
    private let picker = PickerVC()
    
    public func preheat() {
        _ = self.view
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        picker.showsVideo = showsVideo
        viewControllers = [picker]
        navigationBar.isTranslucent = false
        picker.didSelectImage = { [unowned self] pickedImage, isNewPhoto in
            if self.showsFilters {
                let filterVC = FiltersVC(image:pickedImage)
                filterVC.didSelectImage = { filteredImage, isImageFiltered in
                    self.didSelectImage?(filteredImage)
                    if isNewPhoto || isImageFiltered {
                        PhotoSaver.trySaveImage(filteredImage)
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
                if isNewPhoto {
                    PhotoSaver.trySaveImage(pickedImage)
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
                
                let exportSession = AVAssetExportSession(asset: asset, presetName: self.videoCompression)
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
        //force picker load view
        _ = picker.view
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
