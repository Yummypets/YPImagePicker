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
    public var data: Data?
    public var thumbnail: UIImage?
    public var url: URL?
    
    init(data: Data?, thumbnail: UIImage?, videoURL: URL?) {
        self.data = data
        self.thumbnail = thumbnail
        self.url = videoURL
    }
    
    convenience init() {
        self.init(data: nil, thumbnail: nil, videoURL: nil)
    }
}

public enum YPMediaItem {
    case photo(photo: YPPhoto)
    case video(video: YPVideo)
}
