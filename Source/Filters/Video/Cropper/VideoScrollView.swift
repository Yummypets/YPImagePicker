//
//  VideoScrollView.swift
//  PryntTrimmerView
//
//  Created by Henry on 10/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

class VideoScrollView: UIView {

    let scrollView = UIScrollView()
    var contentView = UIView()
    var assetSize = CGSize.zero

    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.delegate = self
        addSubview(scrollView)

        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }

    func setupVideo(with asset: AVAsset) {

        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return }
        let trackSize = track.naturalSize.applying(track.preferredTransform)
        assetSize = CGSize(width: fabs(trackSize.width), height: fabs(trackSize.height))

        scrollView.zoomScale = 1.0 // Reset zoom scale before changing the frame of the content view.
        playerItem = AVPlayerItem(asset: asset)
        let playerFrame = CGRect(x: 0, y: 0, width: assetSize.width, height: assetSize.height)
        addVideoLayer(with: playerFrame)

        scrollView.contentSize = assetSize
        setZoomScaleAndCenter(animated: false)
    }

    private func addVideoLayer(with playerFrame: CGRect) {

        playerLayer?.removeFromSuperlayer()
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = playerFrame
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

        contentView.frame = playerFrame
        contentView.layer.addSublayer(playerLayer!)
    }

    func setZoomScaleAndCenter(animated: Bool) {

        guard assetSize != CGSize.zero else { return }

        let scrollWidth = scrollView.bounds.width - scrollView.contentInset.left - scrollView.contentInset.right
        let scrollHeight = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let scale = max(scrollWidth / assetSize.width, scrollHeight / assetSize.height)
        scrollView.minimumZoomScale = scale
        scrollView.maximumZoomScale = 3.0

        var offset = scrollView.contentOffset
        offset.x = -scrollView.contentInset.left - (scrollWidth - assetSize.width * scale) / 2
        offset.y = -scrollView.contentInset.top - (scrollHeight - assetSize.height * scale) / 2

        scrollView.setZoomScale(scale, animated: animated)
        scrollView.setContentOffset(offset, animated: animated)
    }
}

extension VideoScrollView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let scaledAssetSize = CGSize(width: assetSize.width * scale, height: assetSize.height * scale)
        scrollView.contentSize = scaledAssetSize
    }
}
