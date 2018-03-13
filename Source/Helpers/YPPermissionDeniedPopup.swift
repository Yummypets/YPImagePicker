//
//  YPPermissionDeniedPopup.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

class YPPermissionDeniedPopup {
    
    private let configuration: YPImagePickerConfiguration!
    public required init(configuration: YPImagePickerConfiguration) {
        self.configuration = configuration
    }
    
    func popup(cancelBlock: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(title:
            configuration.wordings.permissionPopup.title,
                                      message: configuration.wordings.permissionPopup.message,
                                      preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: configuration.wordings.permissionPopup.cancel,
                          style: UIAlertActionStyle.cancel,
                          handler: { _ in
                            cancelBlock()
            }))
        alert.addAction(
            UIAlertAction(title: configuration.wordings.permissionPopup.grantPermission,
                          style: .default,
                          handler: { _ in
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
                            } else {
                                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                            }
            }))
        return alert
    }
}
