//
//  YPImagePickerConfiguration.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 18/10/2017.
//  Copyright © 2016 Yummypets. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public struct YPImagePickerConfiguration {
    public init() {}
    
    /// Use this property to modify the default wordings provided.
    public var wordings = YPWordings()
    
    /// Set this to true if you want to force the output to be a squared image. Defaults to false
    @available(*, unavailable, renamed:"onlySquareImagesFromLibrary")
    public var onlySquareImages = false
    
    /// Set this to true if you want to force the  library output to be a squared image. Defaults to false
    public var onlySquareImagesFromLibrary = false
    
    /// Set this to true if you want to force the camera output to be a squared image. Defaults to true
    public var onlySquareImagesFromCamera = true
    
    /// Ex: cappedTo:1024 will make sure images from the library will be
    /// resized to fit in a 1024x1024 box. Defaults to original image size.
    public var libraryTargetImageSize = YPLibraryImageSize.original
    
    /// Enables videos within the library and video taking. Defaults to false
    @available(*, unavailable, renamed:"showsVideoInLibrary")
    public var showsVideo = false
    
    /// Enables videos within the library. Defaults to false
    public var showsVideoInLibrary = false
    
    /// Enables selecting the front camera by default, useful for avatars. Defaults to false
    public var usesFrontCamera = false
    
    /// Adds a Filter step in the photo taking process.  Defaults to true
    public var showsFilters = true
    
    /// Enables you to opt out from saving new (or old but filtered) images to the
    /// user's photo library. Defaults to true.
    public var shouldSaveNewPicturesToAlbum = true
    
    /// Choose the videoCompression.  Defaults to AVAssetExportPresetHighestQuality
    public var videoCompression: String = AVAssetExportPresetHighestQuality
    
    /// Defines the name of the album when saving pictures in the user's photo library.
    /// In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName"
    public var albumName = "DefaultYPImagePickerAlbumName"
    
    /// Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
    /// Default value is `.photo`
    public var startOnScreen: YPPickerScreen = .photo
    
    /// Defines which screens are shown at launch, and their order.
    /// Default value is `[.library, .photo]`
    public var screens: [YPPickerScreen] = [.library, .photo]
    
    /// Defines the time limit for recording videos.
    /// Default is 30 seconds.
    public var videoRecordingTimeLimit: TimeInterval = 30.0
    
    /// Defines the time limit for videos from the library.
    /// Defaults to 60 seconds.
    public var videoFromLibraryTimeLimit: TimeInterval = 60.0
    
    /// Adds a Crop step in the photo taking process, after filters.  Defaults to .none
    public var showsCrop: YPCropType = .none

    /// Adds a Overlay View to the camera
    public var overlayView = UIView()
    
    /// Defines if the status bar should be hidden when showing the picker. Default is true
    public var hidesStatusBar = true
    
    /// List of default filters which will be added on the filter screen
    public var filters:[YPFilterDescriptor] = [
        YPFilterDescriptor(name: "Normal", filterName: ""),
        YPFilterDescriptor(name: "Mono", filterName: "CIPhotoEffectMono"),
        YPFilterDescriptor(name: "Tonal", filterName: "CIPhotoEffectTonal"),
        YPFilterDescriptor(name: "Noir", filterName: "CIPhotoEffectNoir"),
        YPFilterDescriptor(name: "Fade", filterName: "CIPhotoEffectFade"),
        YPFilterDescriptor(name: "Chrome", filterName: "CIPhotoEffectChrome"),
        YPFilterDescriptor(name: "Process", filterName: "CIPhotoEffectProcess"),
        YPFilterDescriptor(name: "Transfer", filterName: "CIPhotoEffectTransfer"),
        YPFilterDescriptor(name: "Instant", filterName: "CIPhotoEffectInstant"),
        YPFilterDescriptor(name: "Sepia", filterName: "CISepiaTone")
    ]
}
