//
//  AssetVideoScrollView.swift
//  PryntTrimmerView
//
//  Created by HHK on 28/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

class AssetVideoScrollView: UIScrollView {

    private var widthConstraint: NSLayoutConstraint?

    let contentView = UIView()
    var maxDuration: Double = 15
    private var generator: AVAssetImageGenerator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {

        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        clipsToBounds = true

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.tag = -1
        addSubview(contentView)

        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0)
        widthConstraint?.isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentSize = contentView.bounds.size
    }

    internal func regenerateThumbnails(for asset: AVAsset) {
        guard let thumbnailSize = getThumbnailFrameSize(from: asset) else {
            return
        }

        generator?.cancelAllCGImageGeneration()
        removeFormerThumbnails()
        let newContentSize = setContentSize(for: asset)
        let visibleThumbnailsCount = Int(ceil(frame.width / thumbnailSize.width))
        let thumbnailCount = thumbnailSize.width > 0 ? Int(ceil(newContentSize.width / thumbnailSize.width)) : 0
        addThumbnailViews(thumbnailCount, size: thumbnailSize)
        let timesForThumbnail = getThumbnailTimes(for: asset, numberOfThumbnails: thumbnailCount)
        generateImages(for: asset, at: timesForThumbnail, with: thumbnailSize, visibleThumnails: visibleThumbnailsCount)
    }

    private func getThumbnailFrameSize(from asset: AVAsset) -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil}

        let assetSize = track.naturalSize.applying(track.preferredTransform)

        let height = frame.height
        let ratio = assetSize.width / assetSize.height
        let width = height * ratio
        return CGSize(width: fabs(width), height: fabs(height))
    }

    private func removeFormerThumbnails() {
        contentView.subviews.forEach({ $0.removeFromSuperview() })
    }

    private func setContentSize(for asset: AVAsset) -> CGSize {

        let contentWidthFactor = CGFloat(max(1, asset.duration.seconds / maxDuration))
        widthConstraint?.isActive = false
        widthConstraint = contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: contentWidthFactor)
        widthConstraint?.isActive = true
        layoutIfNeeded()
        return contentView.bounds.size
    }

    private func addThumbnailViews(_ count: Int, size: CGSize) {

        for index in 0..<count {

            let thumbnailView = UIImageView(frame: CGRect.zero)
            thumbnailView.clipsToBounds = true

            let viewEndX = CGFloat(index) * size.width + size.width

            if viewEndX > contentView.frame.width {
                thumbnailView.frame.size = CGSize(width: size.width + (contentView.frame.width - viewEndX), height: size.height)
                thumbnailView.contentMode = .scaleAspectFill
            } else {
                thumbnailView.frame.size = size
                thumbnailView.contentMode = .scaleAspectFit
            }

            thumbnailView.frame.origin = CGPoint(x: CGFloat(index) * size.width, y: 0)
            thumbnailView.tag = index
            contentView.addSubview(thumbnailView)
        }
    }

    private func getThumbnailTimes(for asset: AVAsset, numberOfThumbnails: Int) -> [NSValue] {

        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfThumbnails)
        var timesForThumbnails = [NSValue]()
        for index in 0..<numberOfThumbnails {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            let nsValue = NSValue(time: cmTime)
            timesForThumbnails.append(nsValue)
        }
        return timesForThumbnails
    }

    private func generateImages(for asset: AVAsset, at times: [NSValue], with maximumSize: CGSize, visibleThumnails: Int) {

        generator = AVAssetImageGenerator(asset: asset)
        generator?.appliesPreferredTrackTransform = true
        let scaledSize = CGSize(width: maximumSize.width * UIScreen.main.scale, height: maximumSize.height *  UIScreen.main.scale)
        generator?.maximumSize = scaledSize
        var count = 0

        let handler: AVAssetImageGeneratorCompletionHandler = { [weak self] (_, cgimage, _, result, error) in
            if let cgimage = cgimage, error == nil && result == AVAssetImageGeneratorResult.succeeded {
                DispatchQueue.main.async(execute: { [weak self] () -> Void in

                    if count == 0 {
                        self?.displayFirstImage(cgimage, visibleThumbnails: visibleThumnails)
                    }
                    self?.displayImage(cgimage, at: count)
                    count += 1
                })
            }
        }

        generator?.generateCGImagesAsynchronously(forTimes: times, completionHandler: handler)
    }

    private func displayFirstImage(_ cgImage: CGImage, visibleThumbnails: Int) {
        for i in 0...visibleThumbnails {
            displayImage(cgImage, at: i)
        }
    }

    private func displayImage(_ cgImage: CGImage, at index: Int) {
        if let imageView = contentView.viewWithTag(index) as? UIImageView {
            let uiimage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImageOrientation.up)
            imageView.image = uiimage
        }
    }
}
