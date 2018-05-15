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
    
    func fetchUrl(for videoAsset: PHAsset, cropRect: CGRect, callback: @escaping (URL) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                
                func getTransform(for videoTrack: AVAssetTrack, with renderSize: CGSize) -> CGAffineTransform {
                
                    let cropFrame = cropRect
                    let renderScale = renderSize.width / cropFrame.width
                    let offset = CGPoint(x: -cropFrame.origin.x, y: -cropFrame.origin.y)
                    let rotation = atan2(videoTrack.preferredTransform.b, videoTrack.preferredTransform.a)
                    
                    var rotationOffset = CGPoint(x: 0, y: 0)
                    
                    if videoTrack.preferredTransform.b == -1.0 {
                        rotationOffset.y = videoTrack.naturalSize.width
                    } else if videoTrack.preferredTransform.c == -1.0 {
                        rotationOffset.x = videoTrack.naturalSize.height
                    } else if videoTrack.preferredTransform.a == -1.0 {
                        rotationOffset.x = videoTrack.naturalSize.width
                        rotationOffset.y = videoTrack.naturalSize.height
                    }
                    
                    var transform = CGAffineTransform.identity
                    transform = transform.scaledBy(x: renderScale, y: renderScale)
                    transform = transform.translatedBy(x: offset.x + rotationOffset.x, y: offset.y + rotationOffset.y)
                    transform = transform.rotated(by: rotation)
                    
//                    print("track size \(videoTrack.naturalSize)")
//                    print("preferred Transform = \(videoTrack.preferredTransform)")
//                    print("rotation angle \(rotation)")
//                    print("rotation offset \(rotationOffset)")
//                    print("actual Transform = \(transform)")
                    return transform
                }
                
                guard let asset = asset, let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
                    return
                }
                
                let assetComposition = AVMutableComposition()
                let trackTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
                
                guard let videoCompositionTrack = assetComposition
                    .addMutableTrack(withMediaType: .video,
                                     preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                        return
                }
                
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: kCMTimeZero)
                
                if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
                    let audioCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: AVMediaType.audio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid)
                    try audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: kCMTimeZero)
                }
                
                //1. Create the instructions
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
                
                //2 add the layer instructions
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                
                let renderSize = cropRect.size
                let transform = getTransform(for: videoTrack, with: renderSize)
                
                layerInstructions.setTransform(transform, at: kCMTimeZero)
                layerInstructions.setOpacity(1.0, at: kCMTimeZero)
                mainInstructions.layerInstructions = [layerInstructions]
                
                //3 Create the main composition and add the instructions
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = renderSize
                videoComposition.instructions = [mainInstructions]
                videoComposition.frameDuration = CMTimeMake(1, 30)
                
                let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())TrimmedMovie.mp4")
                try? FileManager.default.removeItem(at: url)
                
                let exportSession = AVAssetExportSession(asset: assetComposition,
                                                         presetName: AVAssetExportPresetHighestQuality)
                exportSession?.outputFileType = AVFileType.mp4
                exportSession?.shouldOptimizeForNetworkUse = true
                exportSession?.videoComposition = videoComposition
                exportSession?.outputURL = url
                exportSession?.exportAsynchronously(completionHandler: {
                    
                    DispatchQueue.main.async {
                        if let url = exportSession?.outputURL, exportSession?.status == .completed {
                            callback(url)
                        } else {
                            let error = exportSession?.error
                            print("error exporting video \(String(describing: error))")
                        }
                    }
                })
            } catch let error {
                print("💩 \(error)")
            }
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
        requestImageData(for: asset, options: options) { data, _, _, _ in
            if let data = data, let image = UIImage(data: data)?.resetOrientation() {
            
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
        options.isSynchronous = true
        let screenWidth = UIScreen.main.bounds.width
        let ts = CGSize(width: screenWidth, height: screenWidth)
        requestImage(for: asset, targetSize: ts, contentMode: .aspectFill, options: options) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    callback(image)
                }
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
    
    /// This method return two images in the callback. First is with low resolution, second with high.
    /// So the callback fires twice. But with isSynchronous = true there is only one high resolution image.
    /// Bool = isFromCloud
    func fetch(photo asset: PHAsset, callback: @escaping (UIImage, Bool) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
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
