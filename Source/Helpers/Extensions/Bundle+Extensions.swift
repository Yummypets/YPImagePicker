//
//  Bundle+Extensions.swift
//  YPImagePicker
//
//  Created by Roman Tysiachnik on 08.01.2021.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension Bundle {
    static var local: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }
}

private class BundleToken {}
