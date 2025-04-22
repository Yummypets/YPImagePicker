//
//  AVFileType+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import AVFoundation
import MobileCoreServices

extension AVFileType {
    var fileExtension: String {
        if let type = UTType(self.rawValue),
           let ext = type.preferredFilenameExtension {
            return ext
        } else {
            return "None"
        }
    }
}
