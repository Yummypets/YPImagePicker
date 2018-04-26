//
//  YPLoaders.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

struct YPLoaders {
    public static func enableActivityIndicator(barButtonItem: inout UIBarButtonItem?) {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        spinner.color = YPConfig.colors.navigationBarActivityIndicatorColor
        barButtonItem = UIBarButtonItem(customView: spinner)
        spinner.startAnimating()
    }
    
    public static func disableActivityIndicator(barButtonItem: inout UIBarButtonItem?,
                                         title: String,
                                         target: Any,
                                         action: Selector) {
        barButtonItem = UIBarButtonItem(title: title,
                                        style: .plain,
                                        target: target,
                                        action: action)
        barButtonItem?.tintColor = YPConfig.colors.navigationBarTextColor
    }
}
