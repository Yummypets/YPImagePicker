
import AVFoundation
import Foundation
import MobileCoreServices

extension FileManager {
    func removeFileIfNecessary(at url: URL) throws {
        guard fileExists(atPath: url.path) else {
            return
        }

        do {
            try removeItem(at: url)
        }
        catch let error {
            throw TrimError("Couldn't remove existing destination file: \(error)")
        }
    }
}



struct TrimError: Error {
    let description: String
    let underlyingError: Error?

    init(_ description: String, underlyingError: Error? = nil) {
        self.description = "TrimVideo: " + description
        self.underlyingError = underlyingError
    }
}

extension AVMutableComposition {
    convenience init(asset: AVAsset) {
        self.init()
        
        for track in asset.tracks {
            addMutableTrack(withMediaType: track.mediaType, preferredTrackID: track.trackID)
        }
    }
    
    func trim(timeOffStart: Double) {
        let duration = CMTime(seconds: timeOffStart, preferredTimescale: 1)
        let timeRange = CMTimeRange(start: kCMTimeZero, duration: duration)
        
        for track in tracks {
            track.removeTimeRange(timeRange)
        }
        
        removeTimeRange(timeRange)
    }
}

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
            throw TrimError("Error during composition", underlyingError: error)
        }

        return composition
    }

    func export(to destination: URL, removeOldFile: Bool = false, completion: @escaping () -> Void) throws {
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetPassthrough) else {
            throw TrimError("Could not create an export session")
        }
        
        exportSession.outputURL = destination
        exportSession.outputFileType = YPImagePickerConfiguration.shared.videoExtension
        exportSession.shouldOptimizeForNetworkUse = true
        
        if removeOldFile { try FileManager.default.removeFileIfNecessary(at: destination) }
        
        exportSession.exportAsynchronously(completionHandler: completion)
        
        if let error = exportSession.error {
            throw TrimError("error during export", underlyingError: error)
        }
    }
}
