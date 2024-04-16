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
    private let currentExportSessionsAccessQueue = DispatchQueue(label: "LibraryMediaManagerExportArrayAccessQueue")
    internal var currentExportSessions: [ExportData] = [] {
        didSet {
            if exportTimer == nil, !currentExportSessions.isEmpty {
                startExportTimer()
            }
        }
    }

    internal var progress: Float {
        guard !currentExportSessions.isEmpty else { return 0 }
        return currentExportSessions.map { $0.session }.filter { $0.status != .cancelled }.map { $0.progress }.reduce(0.0, +) / Float(currentExportSessions.map { $0.session }.filter { $0.status != .cancelled }.count)
    }

    /// If true then library has items to show. If false the user didn't allow any item to show in picker library.
    internal var hasResultItems: Bool {
        if let fetchResult = self.fetchResult {
            return fetchResult.count > 0
        } else {
            return false
        }
    }

    public init() {}

    private func startExportTimer() {
        DispatchQueue.main.async {
            self.exportTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
                guard let self else { return }
                NotificationCenter.default.post(name: .LibraryMediaManagerExportProgressUpdate, object: self, userInfo: ["progress": progress])
                if let v {
                    v.updateProgress(progress)
                }

                if !self.currentExportSessions.isEmpty, self.currentExportSessions.map({ $0.session }).allSatisfy( { $0.status == .completed || $0.status == .cancelled }) {
                    self.clearExportSessions()
                }
            })
        }
    }

    public func clearExportSessions() {
        DispatchQueue.main.async {
            self.exportTimer?.invalidate()
            self.exportTimer = nil
            self.v?.updateProgress(0)
        }
        currentExportSessions = []
    }

    public func cancelExports() {
        currentExportSessions.forEach { exportData in
            exportData.session.cancelExport()
        }
    }

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
                                presetName: presetName) { session in
                            DispatchQueue.main.async {
                                switch session.status {
                                case .completed:
                                    if let url = session.outputURL {
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

                    if let s = exportSession {
                        self.appendExportData(ExportData(localIdentifier: videoAsset.localIdentifier, session: s))
                    }
                }
            } catch let error {
                ypLog("⚠️ PHCachingImageManager >>> \(error)")
            }
        }
    }

    open func fetchVideoUrlAndCrop(for videoAsset: PHAsset, cropRect: CGRect, timeRange: CMTimeRange = CMTimeRange(start: CMTime.zero, end: CMTime.zero), shouldMute: Bool = false, compressionTypeOverride: String? = nil, processingFailedRetryCount: Int = 0, callback: @escaping (_ videoURL: URL?) -> Void) {
        let videosOptions = PHVideoRequestOptions()
        videosOptions.isNetworkAccessAllowed = true
        videosOptions.deliveryMode = .highQualityFormat
        let isSlowMoVideo = videoAsset.mediaSubtypes.contains(.videoHighFrameRate)
        imageManager?.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
                self.fetchVideoUrlAndCrop(for: asset, assetIdentifier: videoAsset.localIdentifier, cropRect: cropRect, timeRange: timeRange, shouldMute: shouldMute, compressionTypeOverride: compressionTypeOverride, processingFailedRetryCount: processingFailedRetryCount, isSlowMoVideo: isSlowMoVideo, callback: callback)
        }
    }

    open func fetchVideoUrlAndCrop(for videoUrl: URL, cropRect: CGRect, timeRange: CMTimeRange = CMTimeRange(start: CMTime.zero, end: CMTime.zero), shouldMute: Bool = false, compressionTypeOverride: String? = nil, processingFailedRetryCount: Int = 0, callback: @escaping (_ videoURL: URL?) -> Void) {
        let asset = AVAsset(url: videoUrl)
        self.fetchVideoUrlAndCrop(for: asset, assetIdentifier: videoUrl.absoluteString, cropRect: cropRect, timeRange: timeRange, shouldMute: shouldMute, compressionTypeOverride: compressionTypeOverride, processingFailedRetryCount: processingFailedRetryCount, isSlowMoVideo: false, callback: callback)
    }

    private func fetchVideoUrlAndCrop(for videoAsset: AVAsset?, assetIdentifier: String, cropRect: CGRect, timeRange: CMTimeRange = CMTimeRange(start: CMTime.zero, end: CMTime.zero), shouldMute: Bool = false, compressionTypeOverride: String? = nil, processingFailedRetryCount: Int = 0, isSlowMoVideo: Bool = false, callback: @escaping (_ videoURL: URL?) -> Void) {

        guard let asset = videoAsset else { ypLog("⚠️ PHCachingImageManager >>> Don't have the asset"); return }

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

        let presetName: String

        if YPConfig.video.shouldAlwaysProcessVideo {
            presetName = compressionTypeOverride ?? YPConfig.video.compression
        } else {
            presetName = compressionTypeOverride ?? (videoIsCropped || videoIsTrimmed || videoIsRotated || (shouldMute && isSlowMoVideo) ? YPConfig.video.compression : AVAssetExportPresetPassthrough)
        }


        var videoComposition:AVMutableVideoComposition?

        if videoIsCropped {
            // Layer Instructions
            let constrainedCropRectSize = self.getConstrainedSize(size: cropRect.size)
            let scaleFactor = constrainedCropRectSize.height / cropRect.size.height
            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            transform.tx = (videoSize.width < 0) ? abs(videoSize.width) : 0.0
            transform.ty = (videoSize.height < 0) ? abs(videoSize.height) : 0.0
            transform.tx -= cropRect.minX * scaleFactor
            transform.ty -= cropRect.minY * scaleFactor
            transform = transform.scaledBy(x: scaleFactor, y: scaleFactor)
            layerInstructions.setTransform(transform, at: CMTime.zero)

            // CompositionInstruction
            let mainInstructions = AVMutableVideoCompositionInstruction()
            // time range is different from value passed in. Main instructions time range must start at zero.
            mainInstructions.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: timeRange.duration)
            mainInstructions.layerInstructions = [layerInstructions]

            // Video Composition
            videoComposition = AVMutableVideoComposition(propertiesOf: asset)
            videoComposition?.instructions = [mainInstructions]
            videoComposition?.renderSize = cropRect.size
            videoCompositionTrack.preferredTransform = videoTrack.preferredTransform
        } else {
            // transfer the transform so the video renders in the correct orientation
            videoCompositionTrack.preferredTransform = transform
            videoComposition?.renderSize = videoSize
        }

        if let renderSize = videoComposition?.renderSize, YPConfig.video.maxVideoResolution != nil {
            let constrainedSize = self.getConstrainedSize(size: renderSize)
            // Let's make sure that the video has even numbers in the width and height
            let roundedWidth = Int(round(constrainedSize.width / 2.0)) * 2
            let roundedHeight = Int(round(constrainedSize.height / 2.0)) * 2
            videoComposition?.renderSize = CGSize(width: roundedWidth, height: roundedHeight)
        }

        // If we can detect the video is a Slow mo video or we've had a previous processing failure, apply the frame duration / sourceTrackIDForFrameTiming
        // which allows Slow Mo video types to be processed with a selected preset without video composition failures.
        if isSlowMoVideo || processingFailedRetryCount == 1 {
            videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
            videoComposition?.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
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
                            callback(url)
                        } else {
                            ypLog("LibraryMediaManager -> Don't have URL.")
                            callback(nil)
                        }
                    case .failed:
                        if let self = self {
                            var retryCount = processingFailedRetryCount
                            retryCount += 1
                            // Try one more time to process with the export settings on the YPConfig.
                            let compressionOverride = YPConfig.video.compression
                            ypLog("LibraryMediaManager -> Export of the video failed. Reason: \(String(describing: session.error))\n--- Retrying with compression type \(compressionOverride)")
                            if retryCount > 1 {
                                callback(nil)
                            } else {
                                self.fetchVideoUrlAndCrop(for: asset, assetIdentifier: assetIdentifier, cropRect: cropRect, timeRange: timeRange, shouldMute: shouldMute, compressionTypeOverride: compressionOverride, processingFailedRetryCount: retryCount, isSlowMoVideo: isSlowMoVideo, callback: callback)
                            }
                        } else {
                            callback(nil)
                        }
                    default:
                        ypLog("LibraryMediaManager -> Export session completed with \(session.status) status. Not handling.")
                        callback(nil)
                    }
                }
            }

        if let s = exportSession {
            self.appendExportData(ExportData(localIdentifier: assetIdentifier, session: s))
        }
    }

    private func getConstrainedSize(size: CGSize) -> CGSize {
        if let maxVideoResolution = YPConfig.video.maxVideoResolution, size.width * size.height > maxVideoResolution {
            let maxWidth = maxVideoResolution / size.height
            let aspectRatio = size.width / size.height
            let newHeight = maxWidth / aspectRatio
            return CGSize(width: maxWidth, height: newHeight)
        }
        return size
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

    private func appendExportData(_ exportData: ExportData) {
        currentExportSessionsAccessQueue.async { [weak self] in
            guard let self else { return }
            if let index = currentExportSessions.firstIndex(where: { $0.localIdentifier == exportData.localIdentifier }) {
                let session = currentExportSessions[index].session
                session.cancelExport()
                currentExportSessions.remove(at: index)
            }
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
