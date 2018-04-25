//
//  YPMediaItem.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

public struct YPPhoto {
    public let image: UIImage
    public let fromCamera: Bool
    
    init(image: UIImage, fromCamera: Bool = false) {
        self.image = image
        self.fromCamera = fromCamera
    }
}

public class YPVideo {
    public var thumbnail: UIImage
    public var url: URL
    public let fromCamera: Bool

    init(thumbnail: UIImage, videoURL: URL, fromCamera: Bool = false) {
        self.thumbnail = thumbnail
        self.url = videoURL
        self.fromCamera = fromCamera
    }
}

public enum YPMediaItem {
    case photo(p: YPPhoto)
    case video(v: YPVideo)
}

// MARK: - Compression

extension YPVideo {
    /// Fetches a video data with selected compression in YPImagePickerConfiguration
    func fetchData(completion: (_ videoData: Data) -> Void) {
      // TODO: place here a compression code. Use YPConfig.videoCompression and YPConfig.videoExtension
    }
}
