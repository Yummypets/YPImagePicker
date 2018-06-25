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

/// Typealias for code prettiness
internal var YPConfig: YPImagePickerConfiguration { return YPImagePickerConfiguration.shared }

public struct YPImagePickerConfiguration {
    public static var shared: YPImagePickerConfiguration = YPImagePickerConfiguration()
    
    public init() {}
    
    /// Scroll to change modes, defaults to true
    public var isScrollToChangeModesEnabled = true
    
    // Library configuration
    public var library = YPConfigLibrary()
    
    // Video configuration
    public var video = YPConfigVideo()
    
    /// Use this property to modify the default wordings provided.
    public var wordings = YPWordings()
    
    /// Use this property to modify the default icons provided.
    public var icons = YPIcons()
    
    /// Use this property to modify the default colors provided.
    public var colors = YPColors()
    
    /// Set this to true if you want to force the camera output to be a squared image. Defaults to true
    public var onlySquareImagesFromCamera = true
    
    /// Enables selecting the front camera by default, useful for avatars. Defaults to false
    public var usesFrontCamera = false
    
    /// Adds a Filter step in the photo taking process.  Defaults to true
    public var showsFilters = true
    
    /// Enables you to opt out from saving new (or old but filtered) images to the
    /// user's photo library. Defaults to true.
    public var shouldSaveNewPicturesToAlbum = true
    
    /// Defines the name of the album when saving pictures in the user's photo library.
    /// In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName"
    public var albumName = "DefaultYPImagePickerAlbumName"
    
    /// Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
    /// Default value is `.photo`
    public var startOnScreen: YPPickerScreen = .photo
    
    /// Defines which screens are shown at launch, and their order.
    /// Default value is `[.library, .photo]`
    public var screens: [YPPickerScreen] = [.library, .photo]

    /// Adds a Crop step in the photo taking process, after filters.  Defaults to .none
    public var showsCrop: YPCropType = .none
    
    /// Ex: cappedTo:1024 will make sure images from the library or the camera will be
    /// resized to fit in a 1024x1024 box. Defaults to original image size.
    public var targetImageSize = YPImageSize.original
    
    /// Adds a Overlay View to the camera
    public var overlayView = UIView()
    
    /// Defines if the status bar should be hidden when showing the picker. Default is true
    public var hidesStatusBar = true
    
    /// List of default filters which will be added on the filter screen
    public var filters: [YPFilterDescriptor] = [
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
    
    /// Migration
    
    @available(*, obsoleted: 3.0.0, renamed: "video.compression")
    public var videoCompression: String = AVAssetExportPresetHighestQuality
    
    @available(*, obsoleted: 3.0.0, renamed: "video.fileType")
    public var videoExtension: AVFileType = .mov
    
    @available(*, obsoleted: 3.0.0, renamed: "video.recordingTimeLimit")
    public var videoRecordingTimeLimit: TimeInterval = 60.0
    
    @available(*, obsoleted: 3.0.0, renamed: "video.libraryTimeLimit")
    public var videoFromLibraryTimeLimit: TimeInterval = 60.0
    
    @available(*, obsoleted: 3.0.0, renamed: "video.minimumTimeLimit")
    public var videoMinimumTimeLimit: TimeInterval = 3.0
    
    @available(*, obsoleted: 3.0.0, renamed: "video.trimmerMaxDuration")
    public var trimmerMaxDuration: Double = 60.0

    @available(*, obsoleted: 3.0.0, renamed: "video.trimmerMinDuration")
    public var trimmerMinDuration: Double = 3.0
    
    @available(*, obsoleted: 3.0.0, renamed: "library.onlySquare")
    public var onlySquareImagesFromLibrary = false
    
    @available(*, obsoleted: 3.0.0, renamed: "library.onlySquare")
    public var onlySquareFromLibrary = false
    
    @available(*, obsoleted: 3.0.0, renamed: "targetImageSize")
    public var libraryTargetImageSize = YPImageSize.original
    
    @available(*, obsoleted: 3.0.0, renamed: "library.mediaType")
    public var showsVideoInLibrary = false
    
    @available(*, obsoleted: 3.0.0, renamed: "library.mediaType")
    public var libraryMediaType = YPlibraryMediaType.photo
    
    @available(*, obsoleted: 3.0.0, renamed: "library.maxNumberOfItems")
    public var maxNumberOfItems = 1
    
}

/// Encapsulates library specific settings.
public struct YPConfigLibrary {
    
    /// Set this to true if you want to force the library output to be a squared image. Defaults to false
    public var onlySquare = false
    
    /// Choose what media types are available in the library. Defaults to `.photo`
    public var mediaType = YPlibraryMediaType.photo
    
    /// Anything superior than 1 will enable the multiple selection feature.
    public var maxNumberOfItems = 1
    
    /// Anything greater than 1 will desactivate live photo and video modes (library only) and
    // force users to select at least the number of items defined.
    public var minNumberOfItems = 1
    
    /// Allow to skip the selections gallery when selecting the multiple media items. Defaults to false.
    public var skipSelectionsGallery = false
}

/// Encapsulates video specific settings.
public struct YPConfigVideo {
    
    /// Choose the videoCompression.  Defaults to AVAssetExportPresetHighestQuality
    public var compression: String = AVAssetExportPresetHighestQuality
    
    /// Choose the result video extension if you trim or compress a video. Defaults to mov.
    public var fileType: AVFileType = .mov
    
    /// Defines the time limit for recording videos.
    /// Default is 60 seconds.
    public var recordingTimeLimit: TimeInterval = 60.0
    
    /// Defines the time limit for videos from the library.
    /// Defaults to 60 seconds.
    public var libraryTimeLimit: TimeInterval = 60.0
    
    /// Defines the minimum time for the video
    /// Defaults to 3 seconds.
    public var minimumTimeLimit: TimeInterval = 3.0
    
    /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
    public var trimmerMaxDuration: Double = 60.0
    
    /// The minimum duration allowed for the trimming.
    /// The handles won't pan further if the minimum duration is attained.
    public var trimmerMinDuration: Double = 3.0
}

public enum YPlibraryMediaType {
    case photo
    case video
    case photoAndVideo
}
