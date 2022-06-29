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

    var cropRect:CGRect?
    var asset:PHAsset?

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

        // this allows us to display the video with the crop rect without having to export the asset first
        if let cropRect = cropRect, let asset = asset {
            let assetSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
            let assetRect = CGRect(x: 0, y: 0, width: assetSize.width, height: assetSize.height)

            // calculate aspect fit rect
            let widthScale = bounds.size.width / assetSize.width
            let heightScale = bounds.size.height / assetSize.height
            let s = min(widthScale, heightScale)
            let fit = CGRect(x: 0, y: 0, width: assetSize.width * s, height: assetSize.height * s)

            // calculate the scale
            let scale = max(assetSize.width / cropRect.size.width, assetSize.height / cropRect.size.height)
            var targetFrame = fit.applying(CGAffineTransform(scaleX: scale, y: scale))

            // calculate the offset scale relative to the centers of the crop rect and the source video
            let xOffsetScale = (cropRect.midX - assetRect.midX) / assetSize.width
            let yOffsetScale = (cropRect.midY - assetRect.midY) / assetSize.height

            // center the scaled frame and then offset by the difference between the centers of the crop rect and the source asset rect
            targetFrame.origin.x = 0.5 * (bounds.size.width - targetFrame.size.width) - xOffsetScale * targetFrame.size.width
            targetFrame.origin.y = 0.5 * (bounds.size.height - targetFrame.size.height) - yOffsetScale * targetFrame.size.height

            playerView.layer.frame = targetFrame
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
