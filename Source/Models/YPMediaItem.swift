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
import Photos

public class YPMediaPhoto {
    
    public var image: UIImage { return modifiedImage ?? originalImage }
    public let originalImage: UIImage
    public var modifiedImage: UIImage?
    public let fromCamera: Bool
    public let exifMeta: [String: Any]?
    public var asset: PHAsset?
    public var url: URL?
    
    public init(image: UIImage,
                exifMeta: [String: Any]? = nil,
                fromCamera: Bool = false,
                asset: PHAsset? = nil,
                url: URL? = nil) {
        self.originalImage = image
        self.modifiedImage = nil
        self.fromCamera = fromCamera
        self.exifMeta = exifMeta
        self.asset = asset
        self.url = url
    }
}

public class YPMediaVideo {
    
    public var thumbnail: UIImage
    public var url: URL
    public let fromCamera: Bool
    public var asset: PHAsset?

    public init(thumbnail: UIImage, videoURL: URL, fromCamera: Bool = false, asset: PHAsset? = nil) {
        self.thumbnail = thumbnail
        self.url = videoURL
        self.fromCamera = fromCamera
        self.asset = asset
    }
}

public enum YPMediaItem {
    case photo(p: YPMediaPhoto)
    case video(v: YPMediaVideo)
}

// MARK: - Compression

public extension YPMediaVideo {
    /// Fetches the video data from the (already compressed) output file at `url`.
    func fetchData(completion: (_ videoData: Data) -> Void) {
        completion((try? Data(contentsOf: url)) ?? Data())
    }
}

// MARK: - Easy access

public extension Array where Element == YPMediaItem {
    var singlePhoto: YPMediaPhoto? {
        if let f = first, case let .photo(p) = f {
            return p
        }
        return nil
    }
    
    var singleVideo: YPMediaVideo? {
        if let f = first, case let .video(v) = f {
            return v
        }
        return nil
    }
}
