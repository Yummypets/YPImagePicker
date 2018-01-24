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
        config.onlySquareImagesFromLibrary = false
        config.onlySquareImagesFromCamera = true
//        config.libraryTargetImageSize = .original
        config.showsVideo = true //false
//        config.usesFrontCamera = true // false
//        config.showsFilters = true
//        config.shouldSaveNewPicturesToAlbum = true
        config.videoCompression = AVAssetExportPresetHighestQuality
        config.albumName = "MyGreatAppName"
        config.startOnScreen = .library
//        config.videoRecordingTimeLimit = 10
//        config.videoFromLibraryTimeLimit = 10
        
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
        picker.didSelectVideo = { [unowned picker] videoData, videoThumbnailImage in
            // video picked
            self.imageView.image = videoThumbnailImage
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
}
