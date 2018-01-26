//
//  YPAlerts.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPAlerts {
    
    static func videoTooLongAlert(with config: YPImagePickerConfiguration ) -> UIAlertController {
        let msg = String(format: NSLocalizedString("YPImagePickerVideoTooLongDetail",
                                                   tableName: nil,
                                                   bundle: Bundle(for: YPPickerVC.self),
                                                   value: "",
                                                   comment: ""), "\(config.videoFromLibraryTimeLimit)")
        
        let alert = UIAlertController(title: ypLocalized("YPImagePickerVideoTooLongTitle"),
                                      message: msg,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}
