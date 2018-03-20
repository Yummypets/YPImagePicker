//
//  PHCachingImageManager+Helpers.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation
import Photos

extension PHCachingImageManager {
    
    func fetchUrl(for videoAsset: PHAsset, callback: @escaping (URL) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        requestAVAsset(forVideo: videoAsset, options: videosOptions) { v, _, _ in
            guard let urlAsset = v as? AVURLAsset else {
                return
            }
            callback(urlAsset.url)
        }
    }
    
    private func photoImageRequestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.isSynchronous = true // Ok since we're already in a background thread
        return options
    }
    
    func fetchImage(for asset: PHAsset, cropRect: CGRect, targetSize: CGSize, callback: @escaping (UIImage) -> Void) {
        let options = photoImageRequestOptions()
    
        // Fetch Highiest quality image possible.
        requestImageData(for: asset, options: options) { (data, string, orientation, info) in
            if let data = data , let image = UIImage(data: data)?.resetOrientation() {
            
                // Crop the high quality image manually.
                let xCrop: CGFloat = cropRect.origin.x * CGFloat(asset.pixelWidth)
                let yCrop: CGFloat = cropRect.origin.y * CGFloat(asset.pixelHeight)
                let scaledCropRect = CGRect(x: xCrop,
                                            y: yCrop,
                                            width: targetSize.width,
                                            height: targetSize.height)
                if let imageRef = image.cgImage?.cropping(to: scaledCropRect) {
                    let croppedImage = UIImage(cgImage: imageRef)
                    callback(croppedImage)
                }
            }
        }
    }
    
    func fetchPreviewFor(video asset: PHAsset, callback: @escaping (UIImage) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        let screenWidth = UIScreen.main.bounds.width
        let ts = CGSize(width: screenWidth, height: screenWidth)
        requestImage(for: asset, targetSize: ts, contentMode: .aspectFill, options: options) { image, _ in
            if let image = image {
                callback(image)
            }
        }
    }
    
    func fetchPlayerItem(for video: PHAsset, callback: @escaping (AVPlayerItem) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
        videosOptions.isNetworkAccessAllowed = true
        requestPlayerItem(forVideo: video, options: videosOptions, resultHandler: { playerItem, _ in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    callback(playerItem)
                }
            }
        })
    }
    
    // Bool = isFromCloud
    func fetch(photo asset: PHAsset, callback: @escaping (UIImage, Bool) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        requestImage(for: asset,
                     targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                     contentMode: .aspectFill,
                     options: options) { result, info in
                        guard let image = result else {
                            return
                        }
                        DispatchQueue.main.async {
                            var isFromCloud = false
                            if let fromCloud = info?[PHImageResultIsDegradedKey] as? Bool {
                                isFromCloud = fromCloud
                            }
                            callback(image, isFromCloud)
                        }
        }
    }
}
