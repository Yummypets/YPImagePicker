//
//
//  YPVideoCropperVC
//
//  Created by Henry on 06/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
//import PryntTrimmerView

/// A view controller to demonstrate the cropping of a video. Make sure the scene is selected as the initial
// view controller in the storyboard
class YPVideoCropperVC: UIViewController {

    @IBOutlet weak var videoCropView: VideoCropView!
    @IBOutlet weak var selectThumbView: ThumbSelectorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadLibrary()
        videoCropView.setAspectRatio(CGSize(width: 3, height: 2), animated: false)
    }

    @IBAction func selectAsset(_ sender: Any) {
        loadAssetRandomly()
    }

    override func loadAsset(_ asset: AVAsset) {
        selectThumbView.asset = asset
        selectThumbView.delegate = self
        videoCropView.asset = asset
    }

    @IBAction func rotate(_ sender: Any) {

        let newRatio = videoCropView.aspectRatio.width < videoCropView.aspectRatio.height ? CGSize(width: 3, height: 2) :
                                                                                            CGSize(width: 2, height: 3)
        videoCropView.setAspectRatio(newRatio, animated: true)
    }

    @IBAction func crop(_ sender: Any) {

        if let selectedTime = selectThumbView.selectedTime, let asset = videoCropView.asset {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.requestedTimeToleranceBefore = kCMTimeZero
            generator.requestedTimeToleranceAfter = kCMTimeZero
            generator.appliesPreferredTrackTransform = true
            var actualTime = kCMTimeZero
            let image = try? generator.copyCGImage(at: selectedTime, actualTime: &actualTime)
            if let image = image {

                let selectedImage = UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
                let croppedImage = selectedImage.crop(in: videoCropView.getImageCropFrame())!
                UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
            }

            try? prepareAssetComposition()
        }
    }

    func prepareAssetComposition() throws {

        guard let asset = videoCropView.asset, let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            return
        }

        let assetComposition = AVMutableComposition()
        let frame1Time = CMTime(seconds: 0.2, preferredTimescale: asset.duration.timescale)
        let trackTimeRange = CMTimeRangeMake(kCMTimeZero, frame1Time)

        guard let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video,
                                                                           preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }

        try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: kCMTimeZero)

        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
            let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                      preferredTrackID: kCMPersistentTrackID_Invalid)
            try audioCompositionTrack?.insertTimeRange(trackTimeRange, of: audioTrack, at: kCMTimeZero)
        }

        //1. Create the instructions
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)

        //2 add the layer instructions
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)

        let renderSize = CGSize(width: 16 * videoCropView.aspectRatio.width * 18,
                                height: 16 * videoCropView.aspectRatio.height * 18)
        let transform = getTransform(for: videoTrack)

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

        let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = url
        exportSession?.exportAsynchronously(completionHandler: {

            DispatchQueue.main.async {

                if let url = exportSession?.outputURL, exportSession?.status == .completed {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                } else {
                    let error = exportSession?.error
                    print("error exporting video \(String(describing: error))")
                }
            }
        })
    }

    private func getTransform(for videoTrack: AVAssetTrack) -> CGAffineTransform {

        let renderSize = CGSize(width: 16 * videoCropView.aspectRatio.width * 18,
                                height: 16 * videoCropView.aspectRatio.height * 18)
        let cropFrame = videoCropView.getImageCropFrame()
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
}

extension YPVideoCropperVC: ThumbSelectorViewDelegate {
    func didChangeThumbPosition(_ imageTime: CMTime) {
        videoCropView.player?.seek(to: imageTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
}

extension UIImage {
    func crop(in frame: CGRect) -> UIImage? {
        if let croppedImage = self.cgImage?.cropping(to: frame) {
            return UIImage(cgImage: croppedImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}
