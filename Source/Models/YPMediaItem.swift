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
}

public class YPVideo {
    public var thumbnail: UIImage?
    public var url: URL?
    
    init(thumbnail: UIImage?, videoURL: URL?) {
        self.thumbnail = thumbnail
        self.url = videoURL
    }
    
    convenience init() {
        self.init(thumbnail: nil, videoURL: nil)
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
      // TODO: place here a compression code. Use YPImagePickerConfiguration.shared.videoCompression and YPImagePickerConfiguration.shared.videoExtension
    }
}
