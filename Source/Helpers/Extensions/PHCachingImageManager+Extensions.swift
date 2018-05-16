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
    
    func fetchUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect, callback: @escaping (URL) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { print("⚠️ PHCachingImageManager >>> Don't have the asset"); return }
                
                let assetComposition = AVMutableComposition()
                let trackTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
                
                // 1. Inserting audio and video tracks in composition
                
                guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
                    let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { print("⚠️ PHCachingImageManager >>> Problems with video track"); return }
                guard let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first,
                    let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { print("⚠️ PHCachingImageManager >>> Problems with audio track"); return }
                
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: kCMTimeZero)
                try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: kCMTimeZero)

                
                // 2. Create the instructions
                
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = trackTimeRange
                
                // 3. Adding the layer instructions. Transforming
                
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                layerInstructions.setTransform(videoTrack.getTransform(cropRect: cropRect), at: kCMTimeZero)
                layerInstructions.setOpacity(1.0, at: kCMTimeZero)
                mainInstructions.layerInstructions = [layerInstructions]
                
                // 4. Create the main composition and add the instructions
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = cropRect.size
                videoComposition.instructions = [mainInstructions]
                videoComposition.frameDuration = CMTimeMake(1, 30);
                
                // 5. Configuring export session
                
                let exportSession = AVAssetExportSession(asset: assetComposition,
                                                         presetName: YPConfig.videoCompression)
                exportSession?.outputFileType = YPConfig.videoExtension
                exportSession?.shouldOptimizeForNetworkUse = true
                exportSession?.videoComposition = videoComposition
                exportSession?.outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingUniquePathComponent(pathExtension: YPConfig.videoExtension.fileExtension)
                
                // 6. Exporting
                
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
                print("⚠️ PHCachingImageManager >>> \(error)")
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
