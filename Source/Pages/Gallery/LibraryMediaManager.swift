//
//  LibraryMediaManager.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

class LibraryMediaManager {
    
    weak var v: YPLibraryView?
    var collection: PHAssetCollection?
    internal var fetchResult: PHFetchResult<PHAsset>!
    internal var previousPreheatRect: CGRect = .zero
    internal var imageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var currentExportSessions: [AVAssetExportSession] = []
    
    func initialize() {
        imageManager = PHCachingImageManager()
        resetCachedAssets()
    }
    
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    func updateCachedAssets(in collectionView: UICollectionView) {
        let screenWidth = YPImagePickerConfiguration.screenWidth
        let size = screenWidth / 4 * UIScreen.main.scale
        let cellSize = CGSize(width: size, height: size)
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath] = []
            var removedIndexPaths: [IndexPath] = []
            
            previousPreheatRect.differenceWith(rect: preheatRect, removedHandler: { removedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(removedRect)
                removedIndexPaths += indexPaths
            }, addedHandler: { addedRect in
                let indexPaths = collectionView.aapl_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = fetchResult.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = fetchResult.assetsAtIndexPaths(removedIndexPaths)
            
            imageManager?.startCachingImages(for: assetsToStartCaching,
                                             targetSize: cellSize,
                                             contentMode: .aspectFill,
                                             options: nil)
            imageManager?.stopCachingImages(for: assetsToStopCaching,
                                            targetSize: cellSize,
                                            contentMode: .aspectFill,
                                            options: nil)
            previousPreheatRect = preheatRect
        }
    }
    
    func fetchVideoUrlAndCrop(for videoAsset: PHAsset,
                              cropRect: CGRect,
                              callback: @escaping (_ videoURL: URL?) -> Void) {
        fetchVideoUrlAndCropWithDuration(for: videoAsset, cropRect: cropRect, duration: nil, callback: callback)
    }
    
    func fetchVideoUrlAndCropWithDuration(for videoAsset: PHAsset,
                                          cropRect: CGRect,
                                          duration: CMTime?,
                                          callback: @escaping (_ videoURL: URL?) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { print("⚠️ PHCachingImageManager >>> Don't have the asset"); return }
                
                let assetComposition = AVMutableComposition()
                let assetMaxDuration = self.getMaxVideoDuration(between: duration, andAssetDuration: asset.duration)
                let trackTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: assetMaxDuration)
                
                // 1. Inserting audio and video tracks in composition
                
                guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
                    let videoCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: .video,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) else {
                                            print("⚠️ PHCachingImageManager >>> Problems with video track")
                                            return
                                            
                }
                if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first,
                    let audioCompositionTrack = assetComposition
                        .addMutableTrack(withMediaType: AVMediaType.audio,
                                         preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
                }
                
                try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
                
                // Layer Instructions
                let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                var transform = videoTrack.preferredTransform
                let videoSize = videoTrack.naturalSize.applying(transform)
                transform.tx = (videoSize.width < 0) ? abs(videoSize.width) : 0.0
                transform.ty = (videoSize.height < 0) ? abs(videoSize.height) : 0.0
                transform.tx -= cropRect.minX
                transform.ty -= cropRect.minY
                layerInstructions.setTransform(transform, at: CMTime.zero)
                videoCompositionTrack.preferredTransform = transform
                
                // CompositionInstruction
                let mainInstructions = AVMutableVideoCompositionInstruction()
                mainInstructions.timeRange = trackTimeRange
                mainInstructions.layerInstructions = [layerInstructions]
                
                // Video Composition
                let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
                videoComposition.instructions = [mainInstructions]
                videoComposition.renderSize = cropRect.size // needed?
                
                // 5. Configuring export session
                
                let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
                let exportSession = assetComposition
                    .export(to: fileURL,
                            videoComposition: videoComposition,
                            removeOldFile: true) { [weak self] session in
                                DispatchQueue.main.async {
                                    switch session.status {
                                    case .completed:
                                        if let url = session.outputURL {
                                            if let index = self?.currentExportSessions.firstIndex(of: session) {
                                                self?.currentExportSessions.remove(at: index)
                                            }
                                            callback(url)
                                        } else {
                                            print("LibraryMediaManager -> Don't have URL.")
                                            callback(nil)
                                        }
                                    case .failed:
                                        print("LibraryMediaManager")
										print("Export of the video failed : \(String(describing: session.error))")
                                        callback(nil)
                                    default:
										print("LibraryMediaManager")
                                        print("Export session completed with \(session.status) status. Not handled.")
                                        callback(nil)
                                    }
                                }
                }

                // 6. Exporting
                DispatchQueue.main.async {
                    self.exportTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                            target: self,
                                                            selector: #selector(self.onTickExportTimer),
                                                            userInfo: exportSession,
                                                            repeats: true)
                }

                if let s = exportSession {
                    self.currentExportSessions.append(s)
                }
            } catch let error {
                print("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }
    
    private func getMaxVideoDuration(between duration: CMTime?, andAssetDuration assetDuration: CMTime) -> CMTime {
        guard let duration = duration else { return assetDuration }

        if assetDuration <= duration {
            return assetDuration
        } else {
            return duration
        }
    }
    
    @objc func onTickExportTimer(sender: Timer) {
        if let exportSession = sender.userInfo as? AVAssetExportSession {
            if let v = v {
                if exportSession.progress > 0 {
                    v.updateProgress(exportSession.progress)
                }
            }
            
            if exportSession.progress > 0.99 {
                sender.invalidate()
                v?.updateProgress(0)
                self.exportTimer = nil
            }
        }
    }
    
    func forseCancelExporting() {
        for s in self.currentExportSessions {
            s.cancelExport()
        }
    }
}
