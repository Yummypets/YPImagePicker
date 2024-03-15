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
    public var cropRect: CGRect?

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
    
    public var thumbnail: UIImage { return modifiedThumbnail ?? originalThumbnail }
    public let originalThumbnail: UIImage
    public var selectedThumbnail: UIImage
    public var modifiedThumbnail: UIImage?
    public var url: URL { return modifiedUrl ?? originalUrl }
    public let originalUrl: URL
    public var modifiedUrl: URL?
    public let fromCamera: Bool
    public var asset: PHAsset?

    // used to defer clipping and cropping until necessary
    public var timeRange: CMTimeRange?
    public var cropRect: CGRect?

    public init(thumbnail: UIImage, videoURL: URL, fromCamera: Bool = false, asset: PHAsset? = nil) {
        self.originalThumbnail = thumbnail
        self.selectedThumbnail = thumbnail
        self.originalUrl = videoURL
        self.fromCamera = fromCamera
        self.asset = asset
    }
}

public enum YPMediaItem {
    case photo(p: YPMediaPhoto)
    case video(v: YPMediaVideo)

    public var scale: CGFloat? {
        switch self {
        case .photo(let photo):
            guard let pixelWidth = photo.asset?.pixelWidth,
                  let cropWidth = photo.cropRect?.width
            else { return nil }
            return CGFloat(pixelWidth) / cropWidth
        case .video(let video):
            guard let pixelWidth = video.asset?.pixelWidth,
                  let cropWidth = video.cropRect?.width
            else { return nil }
            return CGFloat(pixelWidth) / cropWidth
        }
    }

    public var size: CGSize? {
        switch self {
        case .photo(let photo):
            guard let pixelWidth = photo.asset?.pixelWidth,
                  let pixelHeight = photo.asset?.pixelHeight
            else { return nil }
            return CGSize(width: pixelWidth, height: pixelHeight)
        case .video(let video):
            guard let pixelWidth = video.asset?.pixelWidth,
                  let pixelHeight = video.asset?.pixelHeight
            else { return nil }
            return CGSize(width: pixelWidth, height: pixelHeight)
        }
    }

    public var cropRect: CGRect? {
        switch self {
        case .photo(let photo): photo.cropRect
        case .video(let video): video.cropRect
        }
    }
}

// MARK: - Compression

public extension YPMediaVideo {
    /// Fetches a video data with selected compression in YPImagePickerConfiguration
    func fetchData(completion: (_ videoData: Data) -> Void) {
        // TODO: place here a compression code. Use YPConfig.videoCompression
        // and YPConfig.videoExtension
        completion(Data())
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
