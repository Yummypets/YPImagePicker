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

    public static var LibraryMediaManagerExportProgressUpdate: Notification.Name { return .init(rawValue: "\(namespace).LibraryMediaManagerExportProgressUpdate") }
}

open class LibraryMediaManager {
    struct ExportData {
        let localIdentifier: String
        let session: AVAssetExportSession
    }

    weak var v: YPLibraryView?
    var collection: PHAssetCollection?
    internal var fetchResult: PHFetchResult<PHAsset>?
    internal var previousPreheatRect: CGRect = .zero
    internal var imageManager: PHCachingImageManager?
    internal var exportTimer: Timer?
    internal var exportTimers: [Timer] = []
    internal var currentExportSessions: [ExportData] = []
    private let currentExportSessionsAccessQueue = DispatchQueue(label: "LibraryMediaManagerExportArrayAccessQueue")

    /// If true then library has items to show. If false the user didn't allow any item to show in picker library.
    internal var hasResultItems: Bool {
        if let fetchResult = self.fetchResult {
            return fetchResult.count > 0
        } else {
            return false
        }
    }

    public init() {}

    public func initialize() {
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
                                        if let index = self?.currentExportSessions.firstIndex(where: { $0.session == session }) {
                                            self?.removeExportData(at: index)
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
                        self.appendExportData(ExportData(localIdentifier: videoAsset.localIdentifier, session: s))
                    }
                }
            } catch let error {
                ypLog("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }

    open func fetchVideoUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect, timeRange: CMTimeRange = CMTimeRange(start: CMTime.zero, end: CMTime.zero), shouldMute: Bool = false, compressionTypeOverride: String? = nil, callback: @escaping (_ videoURL: URL?) -> Void) {
        if currentExportSessions.contains(where: { $0.localIdentifier == videoAsset.localIdentifier }) {
            cancelExport(for: videoAsset.localIdentifier)
        }

        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat

        let videoNeedsProcessing = videoAsset.mediaSubtypes.contains(.videoHighFrameRate)

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

                let presetName = compressionTypeOverride ?? (videoIsCropped || videoIsTrimmed || videoIsRotated || (shouldMute && videoNeedsProcessing) ? YPConfig.video.compression : AVAssetExportPresetPassthrough)
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
                                    if let index = self?.currentExportSessions.firstIndex(where: { $0.session == session }) {
                                        self?.removeExportData(at: index)
                                    }
                                    callback(url)
                                } else {
                                    ypLog("LibraryMediaManager -> Don't have URL.")
                                    self?.stopExportTimer(for: session)
                                    callback(nil)
                                }
                            case .failed:
                                if compressionTypeOverride == nil, let self = self {
                                    let compressionOverride = presetName == AVAssetExportPresetPassthrough ? YPConfig.video.compression : AVAssetExportPresetPassthrough
                                    ypLog("LibraryMediaManager -> Export of the video failed. Reason: \(String(describing: session.error))\n--- Retrying with compression type \(compressionOverride)")
                                    self.stopExportTimer(for: session)
                                    self.fetchVideoUrlAndCrop(for: videoAsset, cropRect: cropRect, timeRange: timeRange, shouldMute: shouldMute, compressionTypeOverride: compressionOverride, callback: callback)
                                }
                                else {
                                    ypLog("LibraryMediaManager -> Export of the video failed. Reason: \(String(describing: session.error))")
                                    self?.stopExportTimer(for: session)
                                    callback(nil)
                                }
                            default:
                                ypLog("LibraryMediaManager -> Export session completed with \(session.status) status. Not handling.")
                                self?.stopExportTimer(for: session)
                                callback(nil)
                            }
                        }
                    }

                // 6. Exporting
                DispatchQueue.main.async {
                    self.exportTimers.append(
                        Timer.scheduledTimer(timeInterval: 0.1,
                                             target: self,
                                             selector: #selector(self.onTickExportTimer),
                                             userInfo: exportSession,
                                             repeats: true)
                    )
                }

                if let s = exportSession {
                    self.appendExportData(ExportData(localIdentifier: videoAsset.localIdentifier, session: s))
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
                let progress = [
                    "session": exportSession,
                    "progress": exportSession.progress
                ] as [String : Any]
                NotificationCenter.default.post(name: .LibraryMediaManagerExportProgressUpdate, object: self, userInfo: progress)
            }

            if exportSession.progress > 0.99 {
                stopExportTimer(timer: sender)
                let progress = [
                    "session": exportSession,
                    "progress": 1.0
                ] as [String : Any]
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

    private func stopExportTimer(timer: Timer) {
        timer.invalidate()
        if let index = exportTimers.firstIndex(of: timer) {
            exportTimers.remove(at: index)
        }
        // also reset progress view if one is available
        v?.updateProgress(0)
    }

    private func stopExportTimer(for session: AVAssetExportSession) {
        let timer = exportTimers.first { timer in
            timer.userInfo as? AVAssetExportSession == session
        }
        if let timer {
            stopExportTimer(timer: timer)
        }
    }

    func forceCancelExporting() {
        currentExportSessions.forEach {
            $0.session.cancelExport()
        }
        currentExportSessions = []
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

    func getFirstImageAsset() -> (asset: PHAsset?, index: Int?) {
        guard let fetchResult else { return (nil, nil) }
        var imageAsset: PHAsset?
        var imageIndex: Int?

        fetchResult.enumerateObjects { (asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if asset.mediaType == .image {
                imageAsset = asset
                imageIndex = index
                stop.pointee = true
            }
        }
        return (imageAsset, imageIndex)
    }

    func getAsset(with id: String?) -> PHAsset? {
        guard let fetchResult, let id else { return nil }
        var imageAsset: PHAsset?

        // Try first with current fetchResult, doesn't return asset if not in currently selected album
        fetchResult.enumerateObjects { (asset: PHAsset, _, stop: UnsafeMutablePointer<ObjCBool>) in
            if asset.localIdentifier == id {
                imageAsset = asset
                stop.pointee = true
            }
        }

        if imageAsset == nil {
            imageAsset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: PHFetchOptions()).firstObject
        }

        return imageAsset
    }

    private func cancelExport(for localIdentifier: String) {
        guard let index = currentExportSessions.firstIndex(where: { $0.localIdentifier == localIdentifier }) else { return }
        let exportData = currentExportSessions[index]
        stopExportTimer(for: exportData.session)
        exportData.session.cancelExport()
        removeExportData(at: index)
    }

    private func appendExportData(_ exportData: ExportData) {
        currentExportSessionsAccessQueue.async { [weak self] in
            guard let self else { return }
            currentExportSessions.append(exportData)
        }
    }

    private func removeExportData(at index: Int) {
        currentExportSessionsAccessQueue.async { [weak self] in
            guard let self, currentExportSessions.indices.contains(index) else { return }
            currentExportSessions.remove(at: index)
        }
    }
}
