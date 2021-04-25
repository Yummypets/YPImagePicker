//*
/**
 //
 //  Bundle+Extensions.swift
 //  YPImagePicker
 //
 //  Created by RIcardo Champa on 25.004.2021.
 //  Copyright © 2018 Yummypets. All rights reserved.
 //
*/

import Foundation

extension Bundle {
    static var ypImagePicker: Bundle = {
        let mainBundle = Bundle(for: YPPickerVC.self)
        guard let podBundleURL = mainBundle.url(forResource: "YPImagePicker", withExtension: "bundle"),
                let podBundle = Bundle(url: podBundleURL) else {
            fatalError()
        }
        return podBundle
    }()
}
