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

public class YPVideoView: UIView {
    internal let playerView = UIView()
    internal let playerLayer = AVPlayerLayer()
    internal let playImageView = UIImageView(image: imageFromBundle("yp_play"))
    
    public var player: AVPlayer {
        guard let p = playerLayer.player else {
            print("⚠️ YPVideoView >>> Problems with AVPlayer. Must not see this.")
            return AVPlayer()
        }
        return p
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    internal func setup() {
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGR)
        
        playImageView.alpha = 0.8
        playerLayer.videoGravity = .resizeAspect
        
        sv(
            playerView,
            playImageView
        )
        playImageView.centerInContainer()
        playerView.fillContainer()
        playerView.layer.addSublayer(playerLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = playerView.frame
    }
    
    @objc internal func singleTap() {
        pauseUnpause()
    }
}

// MARK: - Video handling
extension YPVideoView {
    public func loadVideo(video: YPVideo) {
        if let url = video.url {
            let player = AVPlayer(url: url)
            playerLayer.player = player
        } else {
            print("⚠️ YPVideoView >>> Video URL is invalid"); return
        }
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
    }
    
    public func pause() {
        player.pause()
        showPlayImage(show: true)
    }
    
    public func stop() {
        player.pause()
        player.seek(to: kCMTimeZero)
        showPlayImage(show: true)
    }
    
    /// Shows or hide the play image over the view.
    public func showPlayImage(show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.playImageView.alpha = show ? 0.8 : 0
        }
    }
}
