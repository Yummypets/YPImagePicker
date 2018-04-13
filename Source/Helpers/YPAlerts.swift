//
//  YPAlerts.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlerts {
    static func videoTooLongAlert(with config: YPImagePickerConfiguration) -> UIAlertController {
        let msg = String(format: config.wordings.videoDurationPopup.tooLongMessage, "\(config.videoFromLibraryTimeLimit)")
        let alert = UIAlertController(title: config.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: config.wordings.ok, style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert(with config: YPImagePickerConfiguration) -> UIAlertController {
        let msg = String(format: config.wordings.videoDurationPopup.tooShortMessage, "\(config.videoMinimumTimeLimit)")
        let alert = UIAlertController(title: config.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: config.wordings.ok, style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}
