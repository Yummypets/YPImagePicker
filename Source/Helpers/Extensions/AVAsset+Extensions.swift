//
//  AVAsset+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 23.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import AVFoundation

// MARK: Trim

extension AVAsset {
    func assetByTrimming(startTime: CMTime, endTime: CMTime) throws -> AVAsset {
        let timeRange = CMTimeRangeFromTimeToTime(startTime, endTime)
        
        let composition = AVMutableComposition()
        
        do {
            for track in tracks {
                let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
                try compositionTrack?.insertTimeRange(timeRange, of: track, at: kCMTimeZero)
            }
        } catch let error {
            throw YPTrimError("Error during composition", underlyingError: error)
        }
        
        return composition
    }
    
    func getCropVideoComposition(cropRectFrame: CGRect) throws -> (AVMutableVideoComposition, AVMutableComposition) {
        let assetComposition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        let timeRange = CMTimeRangeMake(kCMTimeZero, self.duration)
        var videoTrack: AVAssetTrack?
        
        func getTransform(for videoTrack: AVAssetTrack) -> CGAffineTransform {
            let renderSize = CGSize(width: 16 * cropRectFrame.width * 18,
                                    height: 16 * cropRectFrame.height * 18)
            let cropFrame = cropRectFrame
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
            
            print("track size \(videoTrack.naturalSize)")
            print("preferred Transform = \(videoTrack.preferredTransform)")
            print("rotation angle \(rotation)")
            print("rotation offset \(rotationOffset)")
            print("actual Transform = \(transform)")
            return transform
        }
        
        do {
            for track in tracks {
                // Fill audio and vide tracks
                let compositionTrack = assetComposition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
                try compositionTrack?.insertTimeRange(timeRange, of: track, at: kCMTimeZero)
                // Store a video track
                if track.mediaType == .video { videoTrack = track }
            }
            
            guard let videoTrack = videoTrack else {
                throw YPTrimError("Don't have video track", underlyingError: nil)
            }
            
            
            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstructions.setTransform(getTransform(for: videoTrack), at: kCMTimeZero)
            
            let videoCompositionInstructions = AVMutableVideoCompositionInstruction()
            videoCompositionInstructions.timeRange = timeRange
            videoCompositionInstructions.layerInstructions = [layerInstructions]
            
            //3 Add instructions to the video composition
            videoComposition.renderSize = CGSize(width: 100, height: 100)
//            videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.height)
            videoComposition.instructions = [videoCompositionInstructions]
            videoComposition.frameDuration = CMTimeMake(1, Int32(videoTrack.nominalFrameRate))
            
        } catch let error {
            throw YPTrimError("Error during composition", underlyingError: error)
        }
        
        return (videoComposition, assetComposition)
    }
    
    /// Export the video
    ///
    /// - Parameters:
    ///   - destination: The url to export
    ///   - videoComposition: video composition settings, for example like crop
    ///   - removeOldFile: remove old video
    ///   - completion: resulting export closure
    /// - Throws: YPTrimError with description
    func export(to destination: URL,
                videoComposition: AVVideoComposition? = nil,
                removeOldFile: Bool = false,
                completion: @escaping () -> Void) throws {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetPassthrough) else {
            throw YPTrimError("Could not create an export session")
        }
        
        exportSession.outputURL = destination
        exportSession.outputFileType = YPConfig.videoExtension
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        
        if removeOldFile { try FileManager.default.removeFileIfNecessary(at: destination) }
        
        exportSession.exportAsynchronously(completionHandler: completion)
        
        if let error = exportSession.error {
            throw YPTrimError("error during export", underlyingError: error)
        }
    }
}
