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

    public struct PermissionPopup {
        public var title = ypLocalized("YPImagePickerPermissionDeniedPopupTitle")
        public var message = ypLocalized("YPImagePickerPermissionDeniedPopupMessage")
        public var cancel = ypLocalized("YPImagePickerPermissionDeniedPopupCancel")
        public var grantPermission = ypLocalized("YPImagePickerPermissionDeniedPopupGrantPermission")
    }
    
    public var ok = ypLocalized("YPImagePickerOk")
    public var cancel = ypLocalized("YPImagePickerCancel")
    public var libraryTitle = ypLocalized("YPImagePickerLibrary")
    public var cameraTitle = ypLocalized("YPImagePickerPhoto")
    public var videoTitle = ypLocalized("YPImagePickerVideo")
    public var next = ypLocalized("YPImagePickerNext")
    public var filter = ypLocalized("YPImagePickerFilter")
    public var videoDurationTitle = ypLocalized("YPImagePickerVideoDurationTitle")
    public var videoTooShortMessage = ypLocalized("YPImagePickerVideoTooShort")
    public var videoTooLongMessage = ypLocalized("YPImagePickerVideoTooLong")
    public var warningMaxItemsLimit = ypLocalized("YPImagePickerWarningItemsLimit")
}
