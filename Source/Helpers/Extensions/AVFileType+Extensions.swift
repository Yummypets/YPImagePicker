//
//  AVFileType+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//  Updated by isa yeter on 12.06.2022.

import AVFoundation
import MobileCoreServices

extension AVFileType {
    var fileExtension: String {
        if #available(iOS 14.0, *) {
            guard let type = UTType(self.rawValue),
                  let preferredFilenameExtension = type.preferredFilenameExtension
            else {
                return "None"
            }
            return preferredFilenameExtension
        }
        // Fallback on earlier versions
        else {
            if let ext = UTTypeCopyPreferredTagWithClass(self as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
                return ext as String
            }
            return "None"
        }
    }
}
