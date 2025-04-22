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
    /// Fetch and extension for a file from UTI string
    var fileExtension: String {
        if let type = UTType(self.rawValue as String),  // Используем rawValue
           let ext = type.preferredFilenameExtension {
            return ext
        } else {
            return "None"
        }
    }
}
