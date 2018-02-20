//
//  ViewController.swift
//  YPImagePickerExample
//
//  Created by Sacha DSO on 17/03/2017.
//  Copyright © 2017 Octopepper. All rights reserved.
//

import UIKit
import YPImagePicker
import AVFoundation

class ViewController: UIViewController {
    
    let imageView = UIImageView()
    
    let button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.frame = view.frame
        
        button.setTitle("Pick", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.addSubview(button)
        button.center = view.center
        button.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
    }
    
    @objc
    func showPicker() {
        
        // Configuration
        var config = YPImagePickerConfiguration()
        
        // Uncomment and play around with the configuration 👨‍🔬 🚀

//        /// Set this to true if you want to force the  library output to be a squared image. Defaults to false
//        config.onlySquareImagesFromLibrary = true
//
//        /// Set this to true if you want to force the camera output to be a squared image. Defaults to true
//        config.onlySquareImagesFromCamera = false
//
//        /// Ex: cappedTo:1024 will make sure images from the library will be
//        /// resized to fit in a 1024x1024 box. Defaults to original image size.
//        config.libraryTargetImageSize = .cappedTo(size: 1024)
//
//        /// Enables videos within the library. Defaults to false
        config.showsVideoInLibrary = true
//
//        /// Enables selecting the front camera by default, useful for avatars. Defaults to false
//        config.usesFrontCamera = true
//
//        /// Adds a Filter step in the photo taking process.  Defaults to true
        config.showsFilters = false
//
//        /// Enables you to opt out from saving new (or old but filtered) images to the
//        /// user's photo library. Defaults to true.
//        config.shouldSaveNewPicturesToAlbum = false
//
//        /// Choose the videoCompression.  Defaults to AVAssetExportPresetHighestQuality
//        config.videoCompression = AVAssetExportPreset640x480
//
//        /// Defines the name of the album when saving pictures in the user's photo library.
//        /// In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName"
//        config.albumName = "ThisIsMyAlbum"
//
//        /// Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
//        /// Default value is `.photo`
//        config.startOnScreen = .video
//
//        /// Defines which screens are shown at launch, and their order.
//        /// Default value is `[.library, .photo]`
        config.screens = [.library, .photo, .video]
//
//        /// Defines the time limit for recording videos.
//        /// Default is 30 seconds.
//        config.videoRecordingTimeLimit = 5.0
//
//        /// Defines the time limit for videos from the library.
//        /// Defaults to 60 seconds.
//        config.videoFromLibraryTimeLimit = 10.0
//
//        /// Adds a Crop step in the photo taking process, after filters.  Defaults to .none
        config.showsCrop = .rectangle(ratio: (16/9))
        
        // Set it the default conf for all Pickers
        //      YPImagePicker.setDefaultConfiguration(config)
        // And then use the default configuration like so:
        //      let picker = YPImagePicker()
        
        // Here we use a per picker configuration.
        let picker = YPImagePicker(configuration: config)
        
        // unowned is Mandatory since it would create a retain cycle otherwise :)
        picker.didSelectImage = { [unowned picker] img in
            // image picked
            print(img.size)
            self.imageView.image = img
            picker.dismiss(animated: true, completion: nil)
        }
        picker.didSelectVideo = { [unowned picker] videoData, videoThumbnailImage, url in
            // video picked
            self.imageView.image = videoThumbnailImage
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
}
