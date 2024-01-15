//
//  YPVideoView.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import AVFoundation
import Photos

/// A video view that contains video layer, supports play, pause and other actions.
/// Supports xib initialization.
public class YPVideoView: UIView {
    public let playImageView = UIImageView(image: nil)

    internal var playerView = YPVideoPlayer()
    internal var previewImageView = UIImageView()

    var cropRect: CGRect?
    var asset: PHAsset?

    public var targetAspectRatio: CGFloat?

    public var player: AVPlayer {
        guard playerView.player != nil else {            
            return AVPlayer() // should never happen?
        }
        playImageView.image = YPConfig.icons.playImage
        return playerView.player!
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // Ensure necessary properties are available
        guard let cropRect = cropRect, let asset = asset else { return }
        let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))

        // Check if the aspect ratio adjustment is needed and call appropriate methods
        if let aspectRatio = targetAspectRatio, aspectRatio != assetSize.width / assetSize.height {
            adjustPlayerViewFrameForAspectRatio(cropRect: cropRect, aspectRatio: aspectRatio, assetSize: assetSize)
        } else {
            adjustPlayerViewFrame(cropRect: cropRect, assetSize: assetSize)
        }
    }

    internal func setup() {
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGR)

        // Loop playback
        addReachEndObserver()

        //playerView.alpha = 0
        playImageView.alpha = 0.8
        previewImageView.contentMode = .scaleAspectFit
        
        subviews(
            previewImageView,
            playerView,
            playImageView
        )

        previewImageView.fillContainer()
        playerView.fillContainer()
        playImageView.centerInContainer()
    }

    @objc internal func singleTap() {
        pauseUnpause()
    }

    @objc public func playerItemDidReachEnd(_ note: Notification) {
        guard let item = note.object as? AVPlayerItem else {
            return
        }

        if item == player.currentItem {
            player.actionAtItemEnd = .none
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
}

// MARK: - Player View Adjustment
extension YPVideoView {
    // Method to adjust the player view frame considering the asset's original size
    private func adjustPlayerViewFrame(cropRect: CGRect, assetSize: CGSize) {
        let assetRect = CGRect(origin: .zero, size: assetSize)
        let fitFrame = calculateAspectFitFrame(assetSize: assetSize)
        let targetFrame = calculateTargetFrame(cropRect: cropRect, assetRect: assetRect, fitFrame: fitFrame)
        updatePlayerViewFrame(targetFrame)
    }

    // Method to adjust the player view frame based on a target aspect ratio
    private func adjustPlayerViewFrameForAspectRatio(cropRect: CGRect, aspectRatio: CGFloat, assetSize: CGSize) {
        let adjustedAssetSize = adjustedSizeForAspectRatio(assetSize, aspectRatio: aspectRatio)
        let fitFrame = calculateAspectFitFrame(assetSize: adjustedAssetSize)
        let targetFrame = calculateTargetFrame(cropRect: cropRect, assetRect: CGRect(origin: .zero, size: adjustedAssetSize), fitFrame: fitFrame, adjustForAspectRatio: true)
        updatePlayerViewFrame(targetFrame)
    }

    // Calculate the adjusted size for the asset based on the target aspect ratio
    private func adjustedSizeForAspectRatio(_ assetSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        // Adjust the asset size to maintain the target aspect ratio
        if assetSize.width / assetSize.height > aspectRatio {
            return CGSize(width: assetSize.height * aspectRatio, height: assetSize.height)
        } else {
            return CGSize(width: assetSize.width, height: assetSize.width / aspectRatio)
        }
    }

    // Calculate the frame for aspect fit scaling of the asset
    private func calculateAspectFitFrame(assetSize: CGSize) -> CGRect {
        // Determine the scale factor to fit the asset in the current bounds
        let widthScale = bounds.size.width / assetSize.width
        let heightScale = bounds.size.height / assetSize.height
        let scale = min(widthScale, heightScale)
        return CGRect(origin: .zero, size: CGSize(width: assetSize.width * scale, height: assetSize.height * scale))
    }

    // Calculate the target frame based on the crop rectangle and asset size
    private func calculateTargetFrame(cropRect: CGRect, assetRect: CGRect, fitFrame: CGRect, adjustForAspectRatio: Bool = false) -> CGRect {
        // Determine the scaling factor needed for cropping
        let scale = max(assetRect.size.width / cropRect.size.width, assetRect.size.height / cropRect.size.height)
        var targetFrame = fitFrame.applying(CGAffineTransform(scaleX: scale, y: scale))

        // Calculate offset scaling relative to the crop rectangle and asset rectangle centers
        let xOffsetScale = (cropRect.midX - assetRect.midX) / assetRect.size.width
        let yOffsetScale = (cropRect.midY - assetRect.midY) / assetRect.size.height

        // Adjust the target frame origin based on the calculated offsets
        if adjustForAspectRatio {
            targetFrame.origin.x = 0.5 * (bounds.size.width - targetFrame.size.width) - xOffsetScale
            targetFrame.origin.y = 0.5 * (bounds.size.height - targetFrame.size.height) - yOffsetScale
        } else {
            targetFrame.origin.x = 0.5 * (bounds.size.width - targetFrame.size.width) - xOffsetScale * targetFrame.size.width
            targetFrame.origin.y = 0.5 * (bounds.size.height - targetFrame.size.height) - yOffsetScale * targetFrame.size.height
        }

        return targetFrame
    }

    // Update the frame and video gravity of the player view
    private func updatePlayerViewFrame(_ frame: CGRect) {
        // Set the new frame to the player view layer and adjust video gravity
        playerView.layer.frame = frame
        playerView.playerLayer.videoGravity = .resizeAspectFill
    }
}

// MARK: - Video handling
extension YPVideoView {
    /// The main load video method
    public func loadVideo<T>(_ item: T) {
        // unload any existing video first
        playerView.player?.pause()
        playerView.player?.replaceCurrentItem(with: nil)
        playerView.player = nil

        var player: AVPlayer

        switch item.self {
        case let video as YPMediaVideo:
            player = AVPlayer(url: video.url)
        case let url as URL:
            player = AVPlayer(url: url)
        case let playerItem as AVPlayerItem:
            player = AVPlayer(playerItem: playerItem)
        default:
            return
        }

        playerView.player = player
        playerView.isHidden = false // video is ready so make player visible

        setNeedsLayout()
    }

    /// Convenience func to pause or unpause video dependely of state
    public func pauseUnpause() {
        (player.rate == 0.0) ? play() : pause()
    }

    /// Mute or unmute the video
    public func muteUnmute() {
        player.isMuted = !player.isMuted
    }

    public func play() {
        player.play()
        showPlayImage(show: false)
        addReachEndObserver()
    }

    public func pause() {
        player.pause()
        showPlayImage(show: true)
    }

    public func stop() {
        player.pause()
        player.seek(to: CMTime.zero)
        showPlayImage(show: true)
        removeReachEndObserver()
    }

    public func deallocate() {
        playerView.player = nil
        playImageView.image = nil
    }
}

// MARK: - Other API
extension YPVideoView {
    public func setPreviewImage(_ image: UIImage) {
        previewImageView.image = image
        playerView.isHidden = true // hide the player view until the video is loaded
    }

    /// Shows or hide the play image over the view.
    public func showPlayImage(show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.playImageView.alpha = show ? 0.8 : 0
        }
    }

    public func addReachEndObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }

    /// Removes the observer for AVPlayerItemDidPlayToEndTime. Could be needed to implement own observer
    public func removeReachEndObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: player.currentItem)
    }
}


internal class YPVideoPlayer : UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
