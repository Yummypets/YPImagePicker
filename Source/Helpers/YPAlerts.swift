//
//  YPAlert.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlert {
    static func videoTooLongAlert() -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooLongMessage,
                         "\(YPConfig.video.libraryTimeLimit)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
    
    static func videoTooShortAlert() -> UIAlertController {
        let msg = String(format: YPConfig.wordings.videoDurationPopup.tooShortMessage,
                         "\(YPConfig.video.minimumTimeLimit)")
        let alert = UIAlertController(title: YPConfig.wordings.videoDurationPopup.title,
                                      message: msg,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: YPConfig.wordings.ok, style: UIAlertAction.Style.default, handler: nil))
        return alert
    }
}
