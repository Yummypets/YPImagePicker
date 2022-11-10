//
//  YPWordings.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation

public struct YPWordings {
    
    public var permissionPopup = PermissionPopup()
    public var videoDurationPopup = VideoDurationPopup()

    public struct PermissionPopup {
        public var title = ypLocalized("YPImagePickerPermissionDeniedPopupTitle")
        public var message = ypLocalized("YPImagePickerPermissionDeniedPopupMessage")
        public var cancel = ypLocalized("YPImagePickerPermissionDeniedPopupCancel")
        public var grantPermission = ypLocalized("YPImagePickerPermissionDeniedPopupGrantPermission")
    }
    
    public struct VideoDurationPopup {
        public var title = ypLocalized("YPImagePickerVideoDurationTitle")
        public var tooShortMessage = ypLocalized("YPImagePickerVideoTooShort")
        public var tooLongMessage = ypLocalized("YPImagePickerVideoTooLong")
    }
    
    public var ok = ypLocalized("YPImagePickerOk")
    public var done = ypLocalized("YPImagePickerDone")
    public var cancel = ypLocalized("YPImagePickerCancel")
    public var save = ypLocalized("YPImagePickerSave")
    public var processing = ypLocalized("YPImagePickerProcessing")
    public var trim = ypLocalized("YPImagePickerTrim")
    public var cover = ypLocalized("YPImagePickerCover")
    public var albumsTitle = ypLocalized("YPImagePickerAlbums")
    public var libraryTitle = ypLocalized("YPImagePickerLibrary")
    public var cameraTitle = ypLocalized("YPImagePickerPhoto")
    public var videoTitle = ypLocalized("YPImagePickerVideo")
    public var next = ypLocalized("YPImagePickerNext")
    public var filter = ypLocalized("YPImagePickerFilter")
    public var crop = ypLocalized("YPImagePickerCrop")
    public var warningMaxItemsLimit = ypLocalized("YPImagePickerWarningItemsLimit")
    
    public var textAVAssetExportPresetLowQuality = ypLocalized("Low")
    public var textAVAssetExportPreset640x480 = ypLocalized("Medium (HD)")
    public var textAVAssetExportPresetMediumQuality = ypLocalized("Medium")
    public var textAVAssetExportPreset1920x1080 = ypLocalized("High (Full HD)")
    public var textAVAssetExportPreset1280x720 = ypLocalized("1280 x 720")
    public var textAVAssetExportPresetHighestQuality = ypLocalized("Highest")
    public var textAVAssetExportPresetAppleM4A = ypLocalized("Apple M4A")
    public var textAVAssetExportPreset3840x2160 = ypLocalized("3840 x 2160")
    public var textAVAssetExportPreset960x540 = ypLocalized("960 x 540")
    public var textAVAssetExportPresetPassthrough = ypLocalized("Original")
}
