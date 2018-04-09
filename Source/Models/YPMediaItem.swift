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

public class YPVideo: YPMedia {
    public let type = YPMediaType.video
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

public struct YPMediaItem: YPMedia {
    public var type: YPMediaType
    
    public var photo: YPPhoto?
    public var video: YPVideo?
    
    public init(type: YPMediaType,
         photo: YPPhoto?,
         video: YPVideo?) {
        self.type = type
        self.photo = photo
        self.video = video
    }
}

