//*
/**
YPImagePicker
Created on 25/04/2021
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
