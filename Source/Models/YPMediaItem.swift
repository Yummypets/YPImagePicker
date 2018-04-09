//
//  YPMediaItem.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Foundation

public enum YPMediaType {
    case photo
    case video
}

public protocol YPMedia {
    var type: YPMediaType { get }
}

public struct YPPhoto: YPMedia {
    public let type = YPMediaType.photo
    public let image: UIImage
}

public struct YPVideo: YPMedia {
    public let type = YPMediaType.video
    public let data: Data
    public let thumbnail: UIImage
    public let url: URL
}

public struct YPMediaItem: YPMedia {
    public var type: YPMediaType
    
    public var image: YPPhoto?
    public var video: YPVideo?
    
    public init(type: YPMediaType,
         image: YPPhoto?,
         video: YPVideo?) {
        self.type = type
        self.image = image
        self.video = video
    }
}

