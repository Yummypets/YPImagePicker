//
//  YPVideoProcessor.swift
//  YPImagePicker
//
//  Created by Nik Kov on 13.09.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import AVFoundation

/*
 This class contains all support and helper methods to process the videos
 */
class YPVideoProcessor {

    /// Creates an output path and removes the file in temp folder if existing
    ///
    /// - Parameters:
    ///   - temporaryFolder: Save to the temporary folder or somewhere else like documents folder
    ///   - suffix: the file name wothout extension
    static func makeVideoPathURL(temporaryFolder: Bool, fileName: String) -> URL {
        var outputURL: URL
        
        if temporaryFolder {
            let outputPath = "\(NSTemporaryDirectory())\(fileName).\(YPConfig.video.fileType.fileExtension)"
            outputURL = URL(fileURLWithPath: outputPath)
        } else {
            guard let documentsURL = FileManager
                .default
                .urls(for: .documentDirectory,
                      in: .userDomainMask).first else {
                        print("YPVideoProcessor -> Can't get the documents directory URL")
                return URL(fileURLWithPath: "Error")
            }
            outputURL = documentsURL.appendingPathComponent("\(fileName).\(YPConfig.video.fileType.fileExtension)")
        }
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            do {
                try fileManager.removeItem(atPath: outputURL.path)
            } catch {
                print("YPVideoProcessor -> Can't remove the file for some reason.")
            }
        }
        
        return outputURL
    }
    
    /*
     Crops the video to square by video height from the top of the video.
     */
    static func cropToSquare(filePath: URL, completion: @escaping (_ outputURL : URL?) -> ()) {
        
        // output file
        let outputPath = makeVideoPathURL(temporaryFolder: true, fileName: "squaredVideoFromCamera")
        
        // input file
        let asset = AVAsset.init(url: filePath)
        let composition = AVMutableComposition.init()
        composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // Prevent crash if tracks is empty
        if asset.tracks.isEmpty {
            return
        }
        
        // input clip
        let clipVideoTrack = asset.tracks(withMediaType: .video)[0]
        
        // make it square
        let videoComposition = AVMutableVideoComposition()
        if YPConfig.onlySquareImagesFromCamera {
            videoComposition.renderSize = CGSize(width: CGFloat(clipVideoTrack.naturalSize.height), height: CGFloat(clipVideoTrack.naturalSize.height))
        } else {
            videoComposition.renderSize = CGSize(width: CGFloat(clipVideoTrack.naturalSize.height), height: CGFloat(clipVideoTrack.naturalSize.width))
        }
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        // rotate to potrait
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let t1 = CGAffineTransform(translationX: clipVideoTrack.naturalSize.height, y: -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) / 2)
        let t2: CGAffineTransform = t1.rotated(by: .pi/2)
        let finalTransform: CGAffineTransform = t2
        transformer.setTransform(finalTransform, at: CMTime.zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        // exporter
        let exporter = AVAssetExportSession.init(asset: asset, presetName: YPConfig.video.compression)
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = outputPath
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.outputFileType = YPConfig.video.fileType

        exporter?.exportAsynchronously {
            if exporter?.status == .completed {
                DispatchQueue.main.async(execute: {
                    completion(outputPath)
                })
                return
            } else if exporter?.status == .failed {
                print("YPVideoProcessor -> Export of the video failed. Reason: \(String(describing: exporter?.error))")
            }
            completion(nil)
            return
        }
    }
    
}
