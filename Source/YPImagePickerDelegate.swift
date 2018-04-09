//
//  YPImagePickerDelegate.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation

public protocol YPImagePickerDelegate: class {
    func imagePicker(imagePicker: YPImagePicker, didSelect items: [YPMediaItem])
}
