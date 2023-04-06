//
//  LibraryMediaManager.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos

extension Notification.Name {
    private static var namespace = "YPImagePicker.LibraryMediaManager"

    static var LibraryMediaManagerExportProgressUpdate: Notification.Name { return .init(rawValue: "\(namespace).LibraryMediaManagerExportProgressUpdate") }
}

public class LibraryMediaManager {
    
    weak var v: YPLibraryView?
    var collection: PHAssetCollection?
    internal var fetchResult: PHFetchResult<PHAsset>?
    internal var previousPreheatRect: CGRect = .zero
    internal var imageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var currentExportSessions: [AVAssetExportSession] = []

    /// If true then library has items to show. If false the user didn't allow any item to show in picker library.
    internal var hasResultItems: Bool {
        if let fetchResult = self.fetchResult {
            return fetchResult.count > 0
        } else {
            return false
        }
    }
    
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
            
            guard let assetsToStartCaching = fetchResult?.assetsAtIndexPaths(addedIndexPaths),
                  let assetsToStopCaching = fetchResult?.assetsAtIndexPaths(removedIndexPaths) else {
                ypLog("Some problems in fetching and caching assets.")
                return
            }
            
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
    
    /// Fetch video asset url from PHAsset.
    /// - Parameters:
    ///   - videoAsset: PHAsset which url is requested
    ///   - callback: Returns the AVAsset url for the PHAsset
    func fetchVideoUrl(for videoAsset: PHAsset, callback: @escaping (_ videoURL: URL?) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { ypLog("⚠️ PHCachingImageManager >>> Don't have the asset"); return }

                // pass the asset url through, no need to export
                if let urlAsset = asset as? AVURLAsset {
                    DispatchQueue.main.async {
                        callback(urlAsset.url)
                    }
                } else { /// Some slow-mo videos break with `AVAssetExportPresetPassthrough` so use `AVAssetExportPresetHighestQuality` instead
                    let presetName = AVAssetExportPresetHighestQuality

                    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
                    let exportSession = asset
                        .export(to: fileURL,
                                presetName: presetName) { [weak self] session in
                            DispatchQueue.main.async {
                                switch session.status {
                                case .completed:
                                    if let url = session.outputURL {
                                        if let index = self?.currentExportSessions.firstIndex(of: session) {
                                            self?.currentExportSessions.remove(at: index)
                                        }
                                        callback(url)
                                    } else {
                                        ypLog("LibraryMediaManager -> Don't have URL.")
                                        callback(nil)
                                    }
                                case .failed:
                                    ypLog("LibraryMediaManager -> Export of the video failed. Reason: \(String(describing: session.error))")
                                    callback(nil)
                                default:
                                    ypLog("LibraryMediaManager -> Export session completed with \(session.status) status. Not handling.")
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
                }
            } catch let error {
                ypLog("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }

    func fetchVideoUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect, timeRange: CMTimeRange = CMTimeRange(start: CMTime.zero, end: CMTime.zero), shouldMute: Bool = true, callback: @escaping (_ videoURL: URL?) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat

        let videoIsSlomo = videoAsset.mediaSubtypes.contains(.videoHighFrameRate)

        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
            do {
                guard let asset = asset else { ypLog("⚠️ PHCachingImageManager >>> Don't have the asset"); return }

                let assetComposition = AVMutableComposition()
                let trackTimeRange = timeRange

                // 1. Inserting audio and video tracks in composition

                guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first,
                      let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video,
                                                                                   preferredTrackID: kCMPersistentTrackID_Invalid) else {
                          ypLog("⚠️ PHCachingImageManager >>> Problems with video track")
                          return

                      }
                if !shouldMute, let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first,
                   let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid) {
                    do {
                        try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
                    } catch {
                        ypLog("Unexpected error: \(error).")
                    }
                }

                do {
                    try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
                } catch {
                    ypLog("Unexpected error: \(error).")
                }

                var transform = videoTrack.preferredTransform
                let videoSize = videoTrack.naturalSize.applying(transform)

                let videoIsTrimmed = CMTimeCompare(videoTrack.timeRange.duration, timeRange.duration) != 0
                let videoIsRotated = !transform.isIdentity // transcode the video if source is rotated.

                // 5. Configuring export session
                let videoIsCropped = cropRect.size.width < abs(videoSize.width) || cropRect.size.height < abs(videoSize.height)
                let presetName = videoIsCropped || videoIsTrimmed || videoIsRotated || (shouldMute && videoIsSlomo) ? YPConfig.video.compression : AVAssetExportPresetPassthrough

                var videoComposition:AVMutableVideoComposition?

                if videoIsCropped {
                    // Layer Instructions
                    let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                    transform.tx = (videoSize.width < 0) ? abs(videoSize.width) : 0.0
                    transform.ty = (videoSize.height < 0) ? abs(videoSize.height) : 0.0
                    transform.tx -= cropRect.minX
                    transform.ty -= cropRect.minY
                    layerInstructions.setTransform(transform, at: CMTime.zero)

                    // CompositionInstruction
                    let mainInstructions = AVMutableVideoCompositionInstruction()
                    // time range is different from value passed in. Main instructions time range must start at zero.
                    mainInstructions.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: timeRange.duration)
                    mainInstructions.layerInstructions = [layerInstructions]

                    // Video Composition
                    videoComposition = AVMutableVideoComposition(propertiesOf: asset)
                    videoComposition?.instructions = [mainInstructions]
                    videoComposition?.renderSize = cropRect.size // needed?
                } else {
                    // transfer the transform so the video renders in the correct orientation
                    videoCompositionTrack.preferredTransform = transform
                }

                let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
                let exportSession = assetComposition
                    .export(to: fileURL,
                            videoComposition: videoComposition,
                            removeOldFile: true,
                            presetName: presetName) { [weak self] session in
                        DispatchQueue.main.async {
                            switch session.status {
                            case .completed:
                                if let url = session.outputURL {
                                    if let index = self?.currentExportSessions.firstIndex(of: session) {
                                        self?.currentExportSessions.remove(at: index)
                                    }
                                    callback(url)
                                } else {
                                    ypLog("LibraryMediaManager -> Don't have URL.")
                                    self?.stopExportTimer()
                                    callback(nil)
                                }
                            case .failed:
                                ypLog("LibraryMediaManager -> Export of the video failed. Reason: \(String(describing: session.error))")
                                self?.stopExportTimer()
                                callback(nil)
                            default:
                                ypLog("LibraryMediaManager -> Export session completed with \(session.status) status. Not handling.")
                                self?.stopExportTimer()
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
                ypLog("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }
    
    @objc func onTickExportTimer(sender: Timer) {
        if let exportSession = sender.userInfo as? AVAssetExportSession {
            if let v = v {
                if exportSession.progress > 0 {
                    v.updateProgress(exportSession.progress)
                }
            } else {
                // dispatch notification
                let progress = ["progress": exportSession.progress]
                NotificationCenter.default.post(name: .LibraryMediaManagerExportProgressUpdate, object: self, userInfo: progress)
            }

            if exportSession.progress > 0.99 {
                stopExportTimer()
                let progress = ["progress": Float.zero]
                NotificationCenter.default.post(name: .LibraryMediaManagerExportProgressUpdate, object: self, userInfo: progress)
            }
        }
    }

    private func stopExportTimer() {
        exportTimer?.invalidate()
        exportTimer = nil

        // also reset progress view if one is available
        v?.updateProgress(0)
    }
    
    func forseCancelExporting() {
        for s in self.currentExportSessions {
            s.cancelExport()
        }
    }

    func getAsset(at index: Int) -> PHAsset? {
        guard let fetchResult = fetchResult else {
            ypLog("FetchResult not contain this index: \(index)")
            return nil
        }
        guard fetchResult.count > index else {
            ypLog("FetchResult not contain this index: \(index)")
            return nil
        }
        return fetchResult.object(at: index)
    }
}
