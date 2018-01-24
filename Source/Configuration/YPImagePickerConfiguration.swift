//
//  YPImagePickerConfiguration.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 18/10/2017.
//  Copyright © 2017 ytakzk. All rights reserved.
//

import Foundation
import AVFoundation

public struct YPImagePickerConfiguration {
    public init() {}
    
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
    public var showsVideo = false
    
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
    
    /// Defines the time limit for recording videos.
    /// Default is 30 seconds.
    public var videoRecordingTimeLimit: TimeInterval = 30.0
    
    /// Defines the time limit for videos from the library.
    /// Defaults to 60 seconds.
    public var videoFromLibraryTimeLimit: TimeInterval = 60.0
}
